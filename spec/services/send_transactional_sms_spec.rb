describe SendTransactionalSms, type: :service do
  subject do
    described_class.call(
      phone_number: phone_number, sender_name: sender_name, content: content, record_identifier: "invitation_123"
    )
  end

  let(:sender_name) { "Dept26" }
  let(:phone_number) { "+33648498119" }
  let(:content) { "Bienvenue sur RDV-Solidarités" }
  let(:sib_api_mock) { instance_double(SibApiV3Sdk::TransactionalSMSApi) }
  let(:send_transac_mock) { instance_double(SibApiV3Sdk::SendTransacSms) }

  describe "#call" do
    before do
      allow(SibApiV3Sdk::TransactionalSMSApi).to receive(:new).and_return(sib_api_mock)
      allow(SibApiV3Sdk::SendTransacSms).to receive(:new)
        .with(
          sender: sender_name,
          recipient: phone_number,
          content: content,
          type: "transactional",
          webUrl: Rails.application.routes.url_helpers.brevo_sms_webhooks_url("invitation_123", host: ENV["HOST"])
        )
        .and_return(send_transac_mock)
    end

    it "calls SIB API" do
      expect(sib_api_mock).to receive(:send_transac_sms).with(send_transac_mock)
      subject
    end

    context "when the sending fails" do
      before do
        allow(sib_api_mock).to receive(:send_transac_sms)
          .and_raise(SibApiV3Sdk::ApiError.new("some message"))
      end

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["une erreur est survenue en envoyant le sms. some message"])
      end
    end
  end
end
