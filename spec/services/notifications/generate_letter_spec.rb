describe Notifications::GenerateLetter, type: :service do
  subject do
    described_class.call(
      notification: notification
    )
  end

  include_context "with all existing categories"

  let!(:address) { "20 avenue de Segur, 75007 Paris" }
  let!(:user) do
    create(:user, title: "monsieur", organisations: [organisation], address: address, phone_number: "+33607070707")
  end
  let!(:department) { create(:department) }
  let!(:follow_up) { create(:follow_up, motif_category: category_rsa_orientation) }
  let!(:participation) { create(:participation, follow_up: follow_up, rdv: rdv, user: user) }
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
    create(:messages_configuration, organisation: organisation,
                                    direction_names: ["Direction départemental"], display_department_logo: false)
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
        before { user.phone_number = nil }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["Le numéro de téléphone de l'usager n'est pas renseigné"])
        end
      end

      context "when the phone number is not mobile" do
        before { user.phone_number = "0142244444" }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["Le numéro de téléphone de l'usager n'est pas un mobile"])
        end
      end

      context "when the template attribute are overriden by the configuration attributes" do
        before do
          configuration.update!(template_rdv_title_by_phone_override: "nouveau type de rendez-vous téléphonique")
        end

        it "generates the content with the overriden attributes" do
          subject
          content = unescape_html(notification.content)
          expect(content).to include("20 AVENUE DE SEGUR")
          expect(content).to include("DIRECTION DÉPARTEMENTAL")
          expect(content).to include(
            "Convocation à un nouveau type de rendez-vous téléphonique dans le cadre de votre RSA"
          )
          expect(content).to include(
            "Un travailleur social vous appellera <span class=\"bold-blue\">le dimanche 25 décembre 2022 " \
            "à 09h30</span> sur votre numéro de téléphone: <span class=\"bold-blue\">+33607070707</span>"
          )
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

    context "when the department logo is configured to be displayed" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_department_logo: true)
      end

      it "generates the pdf string with the department logo" do
        subject
        expect(notification.content).to include("department-logo")
      end
    end

    context "when the europe logos are configured to be displayed" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_europe_logos: true)
      end

      it "generates the pdf string with the europe logos" do
        subject
        expect(notification.content).to include("europe-logos")
      end
    end

    context "when the pole emploi logo is configured to be displayed" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_france_travail_logo: true)
      end

      it "generates the pdf string with the pole emploi logo" do
        subject
        expect(notification.content).to include("france-travail-logo")
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
