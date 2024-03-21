RSpec.describe ReplyTransferMailer do
  let!(:source_mail_headers) do
    {
      Subject: "coucou",
      From: "Bénédicte Ficiaire <bene_ficiaire@gmail.com>",
      To: receiver_address,
      Date: "Sun, 25 Jun 2023 12:22:15 +0200"
    }
  end
  let!(:source_mail) do
    Mail.new(headers: source_mail_headers, subject: "coucou", attachments: [])
  end
  let!(:reply_body) { "Je souhaite annuler mon RDV" }
  let!(:organisation) { create(:organisation, email: "organisation@departement.fr") }
  let(:user) do
    create(:user, email: "bene_ficiaire@gmail.com",
                  first_name: "Bénédicte", last_name: "Ficiaire", organisations: [organisation])
  end
  let(:rdv_uuid) { "8fae4d5f-4d63-4f60-b343-854d939881a3" }
  let!(:follow_up) { create(:follow_up, user: user) }
  let!(:participation) { create(:participation, convocable: true, follow_up: follow_up, user: user) }
  let!(:lieu) { create(:lieu) }
  let!(:rdv) do
    create(:rdv, uuid: rdv_uuid, organisation: organisation, participations: [participation],
                 lieu: lieu, starts_at: Date.parse("2023/06/29"))
  end
  let(:invitation) do
    create(:invitation, user: user, organisations: [organisation], created_at: Date.parse("2023/06/22"))
  end

  describe "#forward_invitation_reply_to_organisation" do
    let(:receiver_address) { "invitation+#{invitation.uuid}@reply.rdv-insertion.fr" }
    let!(:mail) do
      described_class.with(
        invitation: invitation,
        reply_body: reply_body,
        source_mail: source_mail
      ).forward_invitation_reply_to_organisation
    end

    it "renders the headers" do
      expect(mail[:from].to_s).to eq("rdv-insertion <support@rdv-insertion.fr>")
      expect(mail.to).to eq(["organisation@departement.fr"])
    end

    it "renders the content" do
      expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager à une invitation :")
      expect(mail.body.encoded).to match("<h4>coucou</h4>")
      expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
      expect(mail.body.encoded).to match("Merci de ne pas répondre à cet e-mail. Pour contacter la personne, ")
      expect(mail.body.encoded).to match("vous pouvez utiliser les informations contenues dans cet e-mail.")
      expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
      expect(mail.body.encoded).to match("M. Bénédicte FICIAIRE")
      expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
      expect(mail.body.encoded).to match("33782605941")
      expect(mail.body.encoded).to match("Invitation à prendre rdv envoyée le jeudi 22 juin 2023 à 00h00")
      expect(mail.body.encoded).to match("Motif : RSA orientation")
      expect(mail.body.encoded).to match(
        "href=\"#{ENV['HOST']}/organisations/#{organisation.id}/users/#{user.id}\""
      )
      expect(mail.body.encoded).to match("Voir la fiche usager")
    end
  end

  describe "when the sender is not the user linked to the invitation or the rdv" do
    let!(:source_mail_headers) do
      {
        Subject: "coucou",
        From: "Random <random@gmail.com>",
        To: receiver_address,
        Date: "Sun, 25 Jun 2023 12:22:15 +0200"
      }
    end

    let(:receiver_address) { "invitation+#{invitation.uuid}@reply.rdv-insertion.fr" }
    let!(:mail) do
      described_class.with(
        invitation: invitation,
        reply_body: reply_body,
        source_mail: source_mail
      ).forward_invitation_reply_to_organisation
    end

    it "renders the headers" do
      expect(mail[:from].to_s).to eq("rdv-insertion <support@rdv-insertion.fr>")
      expect(mail.to).to eq(["organisation@departement.fr"])
    end

    it "renders the content" do
      expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager à une invitation :")
      expect(mail.body.encoded).to match("<h4>coucou</h4>")
      expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
      expect(mail.body.encoded).to match("Merci de ne pas répondre à cet e-mail. Pour contacter la personne, ")
      expect(mail.body.encoded).to match("vous pouvez utiliser les informations contenues dans cet e-mail.")
      expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
      expect(mail.body.encoded).to match("M. Bénédicte FICIAIRE")
      expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
      expect(mail.body.encoded).to match("33782605941")
      expect(mail.body.encoded).to match("Invitation à prendre rdv envoyée le jeudi 22 juin 2023 à 00h00")
      expect(mail.body.encoded).to match("Motif : RSA orientation")
      expect(mail.body.encoded).to match(
        "href=\"#{ENV['HOST']}/organisations/#{organisation.id}/users/#{user.id}\""
      )
      expect(mail.body.encoded).to match("Voir la fiche usager")
    end
  end

  describe "#forward_notification_reply_to_organisation" do
    let!(:receiver_address) { "rdv+8fae4d5f-4d63-4f60-b343-854d939881a3@reply.rdv-insertion.fr" }
    let!(:mail) do
      described_class.with(
        rdv: rdv,
        reply_body: reply_body,
        source_mail: source_mail
      ).forward_notification_reply_to_organisation
    end

    it "renders the headers" do
      expect(mail[:from].to_s).to eq("rdv-insertion <support@rdv-insertion.fr>")
      expect(mail.to).to eq(["organisation@departement.fr"])
    end

    it "renders the content" do
      expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager à une convocation")
      expect(mail.body.encoded).to match("<h4>coucou</h4>")
      expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
      expect(mail.body.encoded).to match("Merci de ne pas répondre à cet e-mail. Pour contacter la personne, ")
      expect(mail.body.encoded).to match("vous pouvez utiliser les informations contenues dans cet e-mail.")
      expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
      expect(mail.body.encoded).to match("M. Bénédicte FICIAIRE")
      expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
      expect(mail.body.encoded).to match("33782605941")
      expect(mail.body.encoded).to match("Message envoyé par rdv-insertion")
      expect(mail.body.encoded).to match("Convocation pour un rdv le jeudi 29 juin 2023 à 00h00")
      expect(mail.body.encoded).to match("Motif : RSA orientation sur site")
      expect(mail.body.encoded).to match("Lieu : DINUM")
      expect(mail.body.encoded).to match("Adresse : 20 avenue de Ségur 75007 Paris")
      expect(mail.body.encoded).to match(
        "href=\"#{ENV['HOST']}/organisations/#{organisation.id}/users/#{user.id}\""
      )
      expect(mail.body.encoded).to match("Voir la fiche usager")
    end

    context "when rdv has no lieu" do
      let!(:lieu) { nil }

      it "renders the content without the lieu" do
        expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager")
        expect(mail.body.encoded).to match("<h4>coucou</h4>")
        expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
        expect(mail.body.encoded).to match("Merci de ne pas répondre à cet e-mail. Pour contacter la personne, ")
        expect(mail.body.encoded).to match("vous pouvez utiliser les informations contenues dans cet e-mail.")
        expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
        expect(mail.body.encoded).to match("M. Bénédicte FICIAIRE")
        expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
        expect(mail.body.encoded).to match("33782605941")
        expect(mail.body.encoded).to match("Message envoyé par rdv-insertion")
        expect(mail.body.encoded).to match("Convocation pour un rdv le jeudi 29 juin 2023 à 00h00")
        expect(mail.body.encoded).to match("Motif : RSA orientation sur site")
        expect(mail.body.encoded).not_to match("Lieu")
        expect(mail.body.encoded).not_to match("Adresse")
        expect(mail.body.encoded).to match(
          "href=\"#{ENV['HOST']}/organisations/#{organisation.id}/users/#{user.id}\""
        )
        expect(mail.body.encoded).to match("Voir la fiche usager")
      end
    end
  end

  describe "#forward_to_default_mailbox" do
    let!(:receiver_address) { "quelquechose@reply.rdv-insertion.fr" }
    let!(:mail) do
      described_class.with(
        reply_body: reply_body,
        source_mail: source_mail
      ).forward_to_default_mailbox
    end

    it "renders the headers" do
      expect(mail[:from].to_s).to eq("rdv-insertion <support@rdv-insertion.fr>")
      expect(mail.to).to eq(["support@rdv-insertion.fr"])
    end

    it "renders the content" do
      expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager")
      expect(mail.body.encoded).to match("<h4>coucou</h4>")
      expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
      expect(mail.body.encoded).to match("Vous trouverez ci-dessous les informations nécessaires pour contacter")
      expect(mail.body.encoded).to match(" la personne ou transmettre ce mail à un agent en charge de son parcours.")
      expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
      expect(mail.body.encoded).to match("M. Bénédicte FICIAIRE")
      expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
      expect(mail.body.encoded).to match("33782605941")
      expect(mail.body.encoded).to match("#{organisation.name} - organisation@departement.fr")
      expect(mail.body.encoded).to match(
        "href=\"#{ENV['HOST']}/departments/#{organisation.department.id}/users/#{user.id}\""
      )
      expect(mail.body.encoded).to match("Voir la fiche usager")
    end

    context "when user is nil" do
      let(:user) { nil }
      let!(:follow_up) { nil }
      let!(:participation) { nil }
      let!(:rdv) { nil }
      let!(:invitation) { nil }

      it "renders the headers" do
        expect(mail[:from].to_s).to eq("rdv-insertion <support@rdv-insertion.fr>")
        expect(mail.to).to eq(["support@rdv-insertion.fr"])
      end

      it "renders the content" do
        expect(mail.body.encoded).to match("Vous trouverez ci-dessous une réponse d'un usager")
        expect(mail.body.encoded).to match("<h4>coucou</h4>")
        expect(mail.body.encoded).to match("Je souhaite annuler mon RDV")
        expect(mail.body.encoded).to match("Vous trouverez ci-dessous les informations nécessaires pour contacter")
        expect(mail.body.encoded).to match(" la personne ou transmettre ce mail à un agent en charge de son parcours.")
        expect(mail.body.encoded).to match("<h4>Éxpéditeur</h4>")
        expect(mail.body.encoded).not_to match("Monsieur Bénédicte FICIAIRE")
        expect(mail.body.encoded).to match("bene_ficiaire@gmail.com")
        expect(mail.body.encoded).not_to match("33782605941")
        expect(mail.body.encoded).not_to match("#{organisation.name} - organisation@departement.fr")
        expect(mail.body.encoded).not_to match("Voir la fiche usager")
      end
    end
  end
end
