describe Brevo::SmsWebhooksController do
  describe "#create" do
    before do
      allow(InboundWebhooks::Brevo::ProcessSmsDeliveryStatusJob).to receive(:perform_async)
    end

    let(:valid_sms_params) do
      { to: "1234567890", msg_status: "delivered", date: "2023-06-07T12:34:56Z", record_identifier: "invitation_1" }
    end

    it "enqueues the job for processing SMS delivery status" do
      expect(InboundWebhooks::Brevo::ProcessSmsDeliveryStatusJob).to receive(:perform_async)
        .with({ to: "1234567890", msg_status: "delivered", date: "2023-06-07T12:34:56Z" }, "invitation_1")
      post :create, params: valid_sms_params, as: :json
      expect(response).to be_successful
    end
  end
end
