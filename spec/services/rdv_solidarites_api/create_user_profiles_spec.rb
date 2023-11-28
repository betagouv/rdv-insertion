describe RdvSolidaritesApi::CreateUserProfiles, type: :service do
  subject do
    described_class.call(
      rdv_solidarites_session: rdv_solidarites_session,
      user_id: user_id, organisation_ids: organisation_ids
    )
  end

  let!(:user_id) { 33 }
  let!(:organisation_ids) { [44, 55] }
  let!(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession::Base) }
  let!(:rdv_solidarites_client) { instance_double(RdvSolidaritesClient) }

  describe "#call" do
    let(:response_body) do
      { referent_assignations: { user_id: user_id, organisation_ids: organisation_ids } }.to_json
    end

    before do
      allow(rdv_solidarites_session).to receive(:rdv_solidarites_client)
        .and_return(rdv_solidarites_client)
      allow(rdv_solidarites_client).to receive(:create_user_profiles)
        .with(user_id, organisation_ids)
        .and_return(OpenStruct.new(success?: true, body: response_body))
    end

    it "tries to assign user to multiple organisations in rdv solidarites" do
      expect(rdv_solidarites_client).to receive(:create_user_profiles)
        .with(user_id, organisation_ids)
      subject
    end

    it "is a success" do
      is_a_success
    end

    context "when the response is unsuccessful" do
      let(:response_body) { { error_messages: ["some error"] }.to_json }

      before do
        allow(rdv_solidarites_client).to receive(:create_user_profiles)
          .with(user_id, organisation_ids)
          .and_return(OpenStruct.new(body: response_body, success?: false))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["Erreur RDV-Solidarités: some error"])
      end
    end
  end
end
