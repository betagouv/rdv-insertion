describe Invitations::SendSms, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  let!(:phone_number_formatted) { "+33782605941" }
  let!(:applicant) do
    create(
      :applicant,
      phone_number_formatted: phone_number_formatted, department: department,
      first_name: "John", last_name: "Doe", title: "monsieur"
    )
  end
  let!(:department) do
    create(
      :department,
      rdv_solidarites_organisation_id: 27,
      number: "26",
      name: "Drôme",
      region: "Auvergne-Rhône-Alpes",
      phone_number: "0147200001"
    )
  end
  let!(:invitation) do
    create(:invitation, applicant: applicant, token: "123", link: "https://www.rdv-solidarites.fr/lieux?invitation_token=123")
  end

  describe "#call" do
    let!(:content) do
      "Monsieur John DOE,\nVous êtes bénéficiaire du RSA et vous allez à ce titre bénéficier d'un "\
        "accompagnement obligatoire. Pour pouvoir choisir la date et l'horaire de votre premier RDV, "\
        "cliquez sur le lien suivant dans les 3 jours: http://www.rdv-insertion.fr/invitations/redirect?token=123\n"\
        "Passé ce délai, vous recevrez une convocation. En cas de problème technique, contactez le 0147200001."
    end

    before do
      allow(SendTransactionalSms).to receive(:call)
      allow(Rails).to receive_message_chain(:env, :production?).and_return(true)
      ENV['HOST'] = "www.rdv-insertion.fr"
    end

    it("is a success") { is_a_success }

    it "calls the send transactional service" do
      expect(SendTransactionalSms).to receive(:call)
        .with(phone_number: phone_number_formatted, content: content)
      subject
    end

    context "when the phone number is blank" do
      let!(:phone_number_formatted) { '' }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["le téléphone doit être renseigné"])
      end
    end
  end
end
