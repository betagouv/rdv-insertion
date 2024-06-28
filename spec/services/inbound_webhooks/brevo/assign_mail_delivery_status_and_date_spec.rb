describe InboundWebhooks::Brevo::AssignMailDeliveryStatusAndDate do
  subject { described_class.call(webhook_params: webhook_params, record: record) }

  let(:webhook_params) { { email: "test@example.com", event: "opened", date: "2023-06-07T12:34:56Z" } }
  let!(:user) { create(:user, email: "test@example.com", invitations: []) }

  context "for an invitation" do
    let!(:invitation) { build(:invitation, user: user) }
    let(:record) { invitation }

    context "when the invitation has a final delivery status" do
      Invitation::FINAL_DELIVERY_STATUS.each do |status|
        it "does not update the invitation if delivery status is #{status}" do
          invitation.update(delivery_status: status, delivered_at: Time.zone.parse("2023-06-07T12:00:00Z"))
          subject
          invitation.reload
          expect(invitation.delivery_status).to eq(status)
          expect(invitation.delivered_at).to eq(Time.zone.parse("2023-06-07T12:00:00Z"))
        end
      end
    end

    context "when the update is old" do
      let(:old_date) { "2022-06-07T12:34:56Z" }

      before do
        invitation.update(delivered_at: Time.zone.parse("2023-06-08T12:34:56Z"))
      end

      it "does not update the invitation" do
        subject
        invitation.reload
        expect(invitation.delivery_status).to be_nil
        expect(invitation.delivered_at).not_to eq(old_date)
      end
    end

    context "when the email does not match" do
      let(:webhook_params) { { email: "mismatch@example.com", event: "opened", date: "2023-06-07T12:34:56Z" } }

      it "does not update the invitation" do
        expect(Sentry).to receive(:capture_message).with("Invitation email and webhook email does not match",
                                                         any_args)
        subject
        expect(invitation.delivery_status).to be_nil
        expect(invitation.delivered_at).to be_nil
      end
    end

    it "updates the invitation with the correct delivery status and date" do
      subject
      invitation.reload
      expect(invitation.delivery_status).to eq("opened")
      expect(invitation.delivered_at).to eq(Time.zone.parse("2023-06-07T12:34:56Z"))
    end
  end

  context "for a notification" do
    let!(:participation) { create(:participation, user: user) }
    let(:notification) { create(:notification, participation: participation) }
    let(:record) { notification }

    context "when the notification has a final delivery status" do
      Notification::FINAL_DELIVERY_STATUS.each do |status|
        it "does not update the notification if delivery status is #{status}" do
          notification.update(delivery_status: status, delivered_at: Time.zone.parse("2023-06-07T12:00:00Z"))
          subject
          notification.reload
          expect(notification.delivery_status).to eq(status)
          expect(notification.delivered_at).to eq(Time.zone.parse("2023-06-07T12:00:00Z"))
        end
      end
    end

    context "when the update is old" do
      let(:old_date) { "2022-06-07T12:34:56Z" }

      before do
        notification.update(delivered_at: Time.zone.parse("2023-06-08T12:34:56Z"))
      end

      it "does not update the notification" do
        subject
        notification.reload
        expect(notification.delivery_status).to be_nil
        expect(notification.delivered_at).not_to eq(old_date)
      end
    end

    context "when the email does not match" do
      let(:webhook_params) { { email: "mismatch@example.com", event: "opened", date: "2023-06-07T12:34:56Z" } }

      it "does not update the notification" do
        expect(Sentry).to receive(:capture_message).with("Notification email and webhook email does not match",
                                                         any_args)
        subject
        expect(notification.delivery_status).to be_nil
        expect(notification.delivered_at).to be_nil
      end
    end

    it "updates the notification with the correct delivery status and date" do
      subject
      notification.reload
      expect(notification.delivery_status).to eq("opened")
      expect(notification.delivered_at).to eq(Time.zone.parse("2023-06-07T12:34:56Z"))
    end
  end
end
