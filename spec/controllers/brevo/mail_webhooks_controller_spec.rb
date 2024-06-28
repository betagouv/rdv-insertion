describe Brevo::MailWebhooksController do
  describe "#create" do
    before do
      allow(InboundWebhooks::Brevo::ProcessMailDeliveryStatusJob).to receive(:perform_async)
    end

    let(:valid_mail_params) do
      {
        email: "test@example.com",
        event: "delivered",
        date: "2023-06-07T12:34:56Z",
        :"X-Mailin-custom" => '{"record_identifier": "invitation_1"}'
      }
    end

    context "when X-Mailin-custom header is present and environment matches" do
      it "enqueues the job for processing mail delivery status" do
        expect(InboundWebhooks::Brevo::ProcessMailDeliveryStatusJob).to receive(:perform_async)
          .with({ email: "test@example.com", event: "delivered", date: "2023-06-07T12:34:56Z" }, "invitation_1")
        post :create, params: valid_mail_params, as: :json
        expect(response).to be_successful
      end
    end

    context "when X-Mailin-custom header is missing" do
      let(:invalid_mail_params) do
        {
          email: "test@example.com",
          event: "delivered",
          date: "2023-06-07T12:34:56Z"
        }
      end

      it "does not enqueue any job" do
        expect(InboundWebhooks::Brevo::ProcessMailDeliveryStatusJob).not_to receive(:perform_async)
        post :create, params: invalid_mail_params, as: :json
        expect(response).to be_successful
      end
    end
  end
end
