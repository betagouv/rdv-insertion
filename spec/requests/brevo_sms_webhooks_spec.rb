RSpec.describe "BrevoSmsWebhooks" do
  let(:webhook_params) do
    {
      to: "0601010101",
      msg_status: "delivered",
      date: "2023-06-07T12:34:56Z"
    }
  end
  let!(:user) { create(:user, phone_number: "0601010101", invitations: []) }

  before do
    allow(InboundWebhooks::Brevo::ProcessSmsDeliveryStatusJob).to receive(:perform_async) do |*args|
      InboundWebhooks::Brevo::ProcessSmsDeliveryStatusJob.new.perform(*args)
    end
    allow(Sentry).to receive(:capture_message)
  end

  context "for an invitation" do
    let!(:invitation) { create(:invitation, user: user) }

    it "processes the webhook and updates the invitation" do
      post "/brevo/sms_webhooks/#{invitation.record_identifier}", params: webhook_params, as: :json
      expect(response).to be_successful

      invitation.reload
      expect(invitation.delivery_status).to eq("delivered")
      expect(invitation.delivered_at).to eq(Time.zone.parse("2023-06-07T12:34:56Z"))
    end

    context "with invalid data" do
      let(:invalid_webhook_params) do
        {
          to: "0987654321",
          msg_status: "delivered",
          date: "2023-06-07T12:34:56Z"
        }
      end

      it "does not update the invitation and captures an error" do
        post "/brevo/sms_webhooks/#{invitation.record_identifier}", params: invalid_webhook_params, as: :json
        expect(response).to be_successful

        invitation.reload
        expect(invitation.delivery_status).to be_nil
        expect(invitation.delivered_at).to be_nil
        expect(Sentry).to have_received(:capture_message).with(
          "Invitation mobile phone and webhook mobile phone does not match", any_args
        )
      end
    end

    context "when invitation is not found" do
      let(:invalid_webhook_params) do
        {
          to: "0601010101",
          msg_status: "delivered",
          date: "2023-06-07T12:34:56Z"
        }
      end

      it "captures an error for missing invitation" do
        post "/brevo/sms_webhooks/invitation_9999", params: invalid_webhook_params, as: :json
        expect(response).to be_successful

        expect(Sentry).to have_received(:capture_message).with("Invitation not found", any_args)
      end
    end
  end

  context "for a notification" do
    let!(:participation) { create(:participation, user: user) }
    let!(:notification) { create(:notification, participation: participation) }

    it "processes the webhook and updates the notification" do
      post "/brevo/sms_webhooks/#{notification.record_identifier}", params: webhook_params, as: :json
      expect(response).to be_successful

      notification.reload
      expect(notification.delivery_status).to eq("delivered")
      expect(notification.delivered_at).to eq(Time.zone.parse("2023-06-07T12:34:56Z"))
    end

    context "when notification is not found" do
      let(:invalid_webhook_params) do
        {
          to: "0601010101",
          msg_status: "delivered",
          date: "2023-06-07T12:34:56Z"
        }
      end

      it "captures an error for missing notification" do
        post "/brevo/sms_webhooks/notification_9999", params: invalid_webhook_params, as: :json
        expect(response).to be_successful

        expect(Sentry).to have_received(:capture_message).with("Notification not found", any_args)
      end
    end
  end
end
