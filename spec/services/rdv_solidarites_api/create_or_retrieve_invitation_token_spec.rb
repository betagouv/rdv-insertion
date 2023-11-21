describe RdvSolidaritesApi::CreateOrRetrieveInvitationToken, type: :service do
  subject do
    described_class.call(
      rdv_solidarites_session: rdv_solidarites_session,
      rdv_solidarites_user_id: rdv_solidarites_user_id
    )
  end

  let!(:rdv_solidarites_user_id) { 27 }
  let!(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession::Base) }
  let!(:rdv_solidarites_client) { instance_double(RdvSolidaritesClient) }

  describe "#call" do
    let!(:invitation_token) { "sometoken" }

    before do
      allow(rdv_solidarites_session).to receive(:rdv_solidarites_client)
        .and_return(rdv_solidarites_client)
      allow(rdv_solidarites_session).to receive(:valid?).and_return(true)
      allow(rdv_solidarites_client).to receive(:invite_user)
        .and_return(OpenStruct.new(success?: true, body: { "invitation_token" => invitation_token }.to_json))
    end

    context "when it succeeds" do
      it("is a success") { is_a_success }

      it "invites the user" do
        expect(rdv_solidarites_client).to receive(:invite_user)
          .with(rdv_solidarites_user_id)
        subject
      end

      it "returns the token" do
        expect(subject.invitation_token).to eq(invitation_token)
      end
    end

    context "when it fails" do
      before do
        allow(rdv_solidarites_client).to receive(:invite_user)
          .and_return(OpenStruct.new(success?: false, body: { error_messages: ["some error"] }.to_json))
      end

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Erreur RDV-Solidarités: some error"])
      end
    end

    context "when the session is nil" do
      let!(:rdv_solidarites_session) { nil }

      before { allow(Sentry).to receive(:capture_message) }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(
          ["Impossible d'appeler RDV-Solidarités. L'équipe a été notifée de l'erreur et tente de la résoudre."]
        )
      end
    end

    context "when the session is invalid" do
      before do
        allow(rdv_solidarites_session).to receive(:valid?).and_return(false)
      end

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["La session n'est plus valide. Reconnectez-vous et réessayez"])
      end
    end
  end
end
