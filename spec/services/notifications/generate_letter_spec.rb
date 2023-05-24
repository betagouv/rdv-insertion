describe Notifications::GenerateLetter, type: :service do
  subject do
    described_class.call(
      notification: notification
    )
  end

  include_context "with all existing categories"

  let!(:address) { "20 avenue de Segur, 75007 Paris" }
  let!(:applicant) do
    create(:applicant, title: "monsieur", organisations: [organisation], address: address, phone_number: "+33607070707")
  end
  let!(:department) { create(:department) }
  let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_orientation) }
  let!(:participation) { create(:participation, rdv_context: rdv_context, rdv: rdv, applicant: applicant) }
  let!(:notification) do
    create(:notification, participation: participation, event: "participation_created", format: "postal")
  end
  let!(:rdv) do
    create(:rdv, lieu: lieu, motif: motif, starts_at: Time.zone.parse("25/12/2022 09:30"), organisation: organisation)
  end
  let!(:motif) do
    create(
      :motif, location_type: "public_office",
              instruction_for_rdv: "Merci de venir au RDV avec un justificatif de domicile et une pièce d'identité."
    )
  end
  let!(:lieu) { create(:lieu, address: "12 Place Léon Blum, 75011 Paris", name: "Marie du 11eme") }

  let!(:organisation) { create(:organisation, department: department) }
  let!(:messages_configuration) do
    create(:messages_configuration, direction_names: ["Direction départemental"], organisation: organisation)
  end
  let!(:configuration) { create(:configuration, motif_category: category_rsa_orientation, organisation: organisation) }

  describe "#call" do
    it("is a success") { is_a_success }

    it "generates the matching content" do
      subject
      content = unescape_html(notification.content)
      expect(content).to include("20 AVENUE DE SEGUR")
      expect(content).to include("DIRECTION DÉPARTEMENTAL")
      expect(content).to include("Convocation à un rendez-vous d'orientation dans le cadre de votre RSA")
      expect(content).to include("le dimanche 25 décembre 2022 à 09h30")
      expect(content).to include("Marie du 11eme")
      expect(content).to include("12 Place Léon Blum, 75011 Paris")
      expect(content).to include(
        "Vous êtes bénéficiaire du RSA et à ce titre " \
        "<span class=\"bold-blue\">vous êtes convoqué à un rendez-vous d'orientation</span>" \
        " afin de démarrer un parcours d'accompagnement"
      )
      expect(content).to include("Merci de venir au RDV avec un justificatif de domicile et une pièce d'identité")
    end

    context "when the motif has no documents warning" do
      let!(:motif) { create(:motif, location_type: "public_office") }

      it "generates the matching content" do
        subject
        content = unescape_html(notification.content)
        expect(content).not_to include("Merci de venir au RDV avec un justificatif de domicile et une pièce")
      end
    end

    context "when the rdv is by phone" do
      let!(:motif) { create(:motif, location_type: "phone") }

      it "generates the matching content" do
        subject
        content = unescape_html(notification.content)
        expect(content).to include("20 AVENUE DE SEGUR")
        expect(content).to include("DIRECTION DÉPARTEMENTAL")
        expect(content).to include("Convocation à un rendez-vous d'orientation téléphonique dans le cadre de votre RSA")
        expect(content).to include(
          "Un travailleur social vous appellera <span class=\"bold-blue\">le dimanche 25 décembre 2022 à 09h30</span>" \
          " sur votre numéro de téléphone: <span class=\"bold-blue\">+33607070707</span>"
        )
        expect(content).not_to include("Merci de venir au RDV avec un justificatif de domicile et une pièce")
      end

      context "when the phone number is blank" do
        before { applicant.phone_number = nil }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["Le numéro de téléphone de l'allocataire n'est pas renseigné"])
        end
      end

      context "when the phone number is not mobile" do
        before { applicant.phone_number = "0142244444" }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["Le numéro de téléphone de l'allocataire n'est pas un mobile"])
        end
      end
    end

    context "when it is a participation cancelled notification" do
      let!(:notification) do
        create(:notification, participation: participation, event: "participation_cancelled", format: "postal")
      end

      it "generates the matching content" do
        subject
        content = unescape_html(notification.content)
        expect(content).to include("20 AVENUE DE SEGUR")
        expect(content).to include("DIRECTION DÉPARTEMENTAL")
        expect(content).to include("Votre rendez-vous d'orientation dans le cadre de votre RSA a été annulé")
        expect(content).to include("le dimanche 25 décembre 2022 à 09h30")
        expect(content).to include(
          "Votre rendez-vous d'orientation prévu le dimanche 25 décembre 2022 à 09h30 " \
          "dans le cadre de votre RSA a été annulé"
        )
      end
    end

    context "when it is a participation updated notification" do
      let!(:notification) do
        create(:notification, participation: participation, event: "participation_updated", format: "postal")
      end

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["L'évènement participation_updated n'est pas pris en charge pour le courrier"])
      end
    end

    context "when the format is not postal" do
      before { notification.format = "email" }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Génération d'une lettre alors que le format est email"])
      end
    end

    context "when the address is blank" do
      let!(:address) { nil }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["L'adresse doit être renseignée"])
      end
    end

    context "when the address is invalid" do
      let!(:address) { "10 rue quincampoix" }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(
          [
            "Le format de l'adresse est invalide. Le format attendu est le suivant: 10 rue de l'envoi 12345 - La Ville"
          ]
        )
      end
    end
  end
end
