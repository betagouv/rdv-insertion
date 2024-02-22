describe Invitations::SaveAndSend, type: :service do
  subject do
    described_class.call(invitation:, check_creneaux_availability:)
  end

  let!(:user) { create(:user) }
  let!(:invitation) { create(:invitation, user: user, sent_at: nil) }
  let(:check_creneaux_availability) { true }

  describe "#call" do
    before do
      allow(Invitations::AssignLinkAndToken).to receive(:call)
        .with(invitation:)
        .and_return(OpenStruct.new(success?: true))
      allow(Invitations::Validate).to receive(:call)
        .with(invitation:)
        .and_return(OpenStruct.new(success?: true))
      allow(RdvSolidaritesApi::RetrieveCreneauAvailability).to receive(:call)
        .with(link_params: invitation.link_params)
        .and_return(OpenStruct.new(success?: true, creneau_availability: true))
      allow(invitation).to receive_messages(send_to_user: OpenStruct.new(success?: true),
                                            rdv_solidarites_token?: false, link?: false)
    end

    it "is a success" do
      is_a_success
    end

    it "returns an invitation" do
      expect(subject.invitation).to eq(invitation)
    end

    it "saves an invitation" do
      expect(Invitations::AssignLinkAndToken).to receive(:call)
        .with(invitation:)
      subject
    end

    it "sends the invitation" do
      expect(invitation).to receive(:send_to_user)
      subject
    end

    it "marks the invitation as sent" do
      subject
      expect(invitation.reload.sent_at).not_to be_nil
    end

    context "when it fails to assign attributes" do
      before do
        allow(Invitations::AssignLinkAndToken).to receive(:call)
          .with(invitation:)
          .and_return(OpenStruct.new(success?: false, errors: ["cannot assign token"]))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["cannot assign token"])
      end
    end

    context "when the validation fails" do
      before do
        allow(Invitations::Validate).to receive(:call)
          .with(invitation:)
          .and_return(OpenStruct.new(success?: false, errors: ["validation failed"]))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["validation failed"])
      end
    end

    context "when it fails to send invitation" do
      before do
        allow(invitation).to receive(:send_to_user)
          .and_return(OpenStruct.new(success?: false, errors: ["something happened"]))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["something happened"])
      end

      it "does not mark the invitation as sent" do
        subject
        expect(invitation.reload.sent_at).to be_nil
      end
    end

    context "when there is a token and a link assigned already" do
      before do
        allow(invitation).to receive_messages(rdv_solidarites_token?: true, link?: true)
      end

      it("is a success") { is_a_success }

      it "does not call the assign link and token service" do
        expect(Invitations::AssignLinkAndToken).not_to receive(:call)
        subject
      end
    end

    context "when it fails to mark as sent" do
      before do
        allow(invitation).to receive(:save)
          .and_return(false)
        allow(invitation).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("some error")
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["some error"])
      end
    end

    context "when there are no creneau available on rdvs" do
      before do
        allow(RdvSolidaritesApi::RetrieveCreneauAvailability).to receive(:call)
          .with(link_params: invitation.link_params)
          .and_return(OpenStruct.new(success?: true, creneau_availability: false))
      end

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "<strong>Il n'y a plus de créneaux disponibles</strong> pour inviter cet utilisateur. <br/><br/>" \
          "Nous vous invitons à créer de nouvelles plages d'ouverture ou augmenter le délai de prise de rdv depuis " \
          "RDV-Solidarités pour pouvoir à nouveau envoyer des invitations.<br/><br/>Plus d'informations sur " \
          "<a href='https://rdv-insertion.gitbook.io/guide-dutilisation-rdv-insertion/configurer-loutil-et-envoyer" \
          "-des-invitations/envoyer-des-invitations-ou-convocations/inviter-les-personnes-a-prendre-rdv#cas-" \
          "des-creneaux-indisponibles' target='_blank' class='link-purple-underlined'>notre guide</a>."
        )
      end

      context "when we don't check the creneau availability" do
        let!(:check_creneaux_availability) { false }

        it("is a success") { is_a_success }

        it "does not call the retrieve creneau service" do
          expect(RdvSolidaritesApi::RetrieveCreneauAvailability).not_to receive(:call)
          subject
        end
      end
    end
  end
end
