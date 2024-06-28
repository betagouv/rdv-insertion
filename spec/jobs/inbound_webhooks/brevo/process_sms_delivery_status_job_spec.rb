describe InboundWebhooks::Brevo::ProcessSmsDeliveryStatusJob do
  subject { described_class.new.perform(webhook_params, record_identifier) }

  let(:webhook_params) { { to: "0601010101", msg_status: "delivered", date: "2023-06-07T12:34:56Z" } }

  before do
    allow(Sentry).to receive(:capture_message)
  end

  context "for an invitation" do
    let!(:invitation) { create(:invitation) }
    let(:record_identifier) { invitation.record_identifier }

    it "processes SMS delivery status" do
      expect(InboundWebhooks::Brevo::AssignSmsDeliveryStatusAndDate).to receive(:call)
        .with(webhook_params: webhook_params, record: invitation)
      subject
    end

    context "when invitation is not found" do
      let(:record_identifier) { "invitation_9999" }

      it "captures an error for missing invitation" do
        subject
        expect(Sentry).to have_received(:capture_message).with("Invitation not found", any_args)
      end
    end
  end

  context "for a notification" do
    let!(:notification) { create(:notification) }
    let(:record_identifier) { notification.record_identifier }

    it "processes SMS delivery status" do
      expect(InboundWebhooks::Brevo::AssignSmsDeliveryStatusAndDate).to receive(:call)
        .with(webhook_params: webhook_params, record: notification)
      subject
    end

    context "when notification is not found" do
      let(:record_identifier) { "notification_9999" }

      it "captures an error for missing notification" do
        subject
        expect(Sentry).to have_received(:capture_message).with("Notification not found", any_args)
      end
    end
  end
end
