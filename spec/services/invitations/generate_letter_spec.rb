describe Invitations::GenerateLetter, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  include_context "with all existing categories"

  let!(:address) { "20 avenue de Segur, 75007 Paris" }
  let!(:applicant) { create(:applicant, organisations: [organisation], address: address) }
  let!(:department) { create(:department) }
  let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_orientation) }
  let!(:invitation) do
    create(
      :invitation, content: nil, applicant: applicant, organisations: [organisation],
                   department: department, format: "postal", rdv_context: rdv_context
    )
  end
  let!(:messages_configuration) { create(:messages_configuration, direction_names: ["Direction départemental"]) }
  let!(:configuration) { create(:configuration, motif_category: category_rsa_orientation) }
  let!(:organisation) do
    create(:organisation, messages_configuration: messages_configuration,
                          department: department, configurations: [configuration])
  end

  describe "#call" do
    it("is a success") { is_a_success }

    it "generates the pdf string with the invitation code" do
      subject
      content = unescape_html(invitation.content)
      expect(content).to include("20 AVENUE DE SEGUR")
      expect(content).to include("DIRECTION DÉPARTEMENTAL")
      expect(content).to include("Pour choisir un créneau à votre convenance, saisissez le code d’invitation")
      expect(content).to include(invitation.uuid)
      expect(content).to include(department.name)
      expect(content).to include("Vous êtes bénéficiaire du RSA")
      # letter-first-col is only used when display_europe_logos is true (false by default)
      expect(content).not_to include("europe-logos")
    end

    context "when the format is not postal" do
      let!(:invitation) { create(:invitation, applicant: applicant, format: "sms") }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Génération d'une lettre alors que le format est sms"])
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
        expect(subject.errors).to eq(["Le format de l'adresse est invalide"])
      end
    end

    context "when the signature is configured" do
      let!(:messages_configuration) { create(:messages_configuration, signature_lines: ["Fabienne Bouchet"]) }

      it "generates the pdf string with the right signature" do
        subject
        expect(invitation.content).to include("Fabienne Bouchet")
      end
    end

    context "when the europe logos are configured to be displayed" do
      let!(:messages_configuration) { create(:messages_configuration, display_europe_logos: true) }

      it "generates the pdf string with the europe logos" do
        subject
        # europe-logos is only used when display_europe_logos is true
        expect(invitation.content).to include("europe-logos")
      end
    end

    context "when the help address is configured" do
      let!(:messages_configuration) do
        create(:messages_configuration, help_address: "10, rue du Conseil départemental 75001 Paris")
      end

      it "renders the mail with the help address" do
        subject
        expect(invitation.content).to include("10, rue du Conseil départemental 75001 Paris")
      end
    end

    context "when the invitation is not in a referent context" do
      it "generates the pdf with no reference to a referent" do
        subject
        expect(invitation.content).not_to include("Référent de parcours")
      end
    end

    context "when the invitation is in a referent context and the applicant has a referent" do
      let!(:invitation) do
        create(
          :invitation, content: nil, applicant: applicant, organisations: [organisation],
                       department: department, format: "postal", rdv_context: rdv_context, rdv_with_referents: true
        )
      end
      let!(:agent) do
        create(:agent, organisations: [organisation], applicants: [applicant],
                       first_name: "Kylian", last_name: "Mbappé")
      end

      it "displays the name of the referent" do
        subject
        expect(invitation.content).to include("Référent de parcours : Kylian Mbappé")
      end
    end

    context "when the context is orientation" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_orientation) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include("Objet : Rendez-vous d'orientation dans le cadre de votre RSA")
        expect(content).to include(
          "vous devez vous présenter à un rendez-vous d'orientation afin de démarrer un parcours d'accompagnement"
        )
        expect(content).to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).not_to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is orientation_france_travail" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_orientation_france_travail) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Premier rendez-vous d'orientation France Travail dans le cadre de votre RSA"
        )
        expect(content).to include(
          "vous devez vous présenter à un premier rendez-vous d'orientation France Travail"
        )
        expect(content).to include(
          "Dans le cadre du projet 'France Travail', ce rendez-vous sera réalisé par deux"
        )
        expect(content).to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).not_to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is accompagnement" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_accompagnement) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include("Objet : Rendez-vous d'accompagnement dans le cadre de votre RSA")
        expect(content).to include(
          "vous devez vous présenter à un rendez-vous d'accompagnement afin de démarrer un parcours d'accompagnement"
        )
        expect(content).to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end

      context "when the organisation is independent from the cd" do
        let!(:organisation) do
          create(:organisation, messages_configuration: messages_configuration,
                                department: department, independent_from_cd: true)
        end

        it "generates the pdf with the right content" do
          subject
          content = unescape_html(invitation.content)
          expect(content).to include("nous serons dans l’obligation d’en informer le Conseil Départemental")
        end
      end
    end

    context "when the context is rsa_cer_signature" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_cer_signature) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Rendez-vous de signature de CER dans le cadre de votre RSA"
        )
        expect(content).to include(
          "vous devez vous présenter à un rendez-vous de signature de CER afin de " \
          "construire et signer votre Contrat d'Engagement Réciproque"
        )
        expect(content).to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).not_to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is rsa_follow_up" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_follow_up) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Rendez-vous de suivi dans le cadre de votre RSA"
        )
        expect(content).to include(
          "vous devez vous présenter à un rendez-vous de suivi afin de faire un point avec votre référent de parcours"
        )
        expect(content).not_to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).not_to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is rsa_insertion_offer" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_insertion_offer) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Participation à un atelier dans le cadre de votre RSA"
        )
        expect(content).to include(
          "Pour en profiter au mieux, nous vous invitons à vous inscrire directement" \
          " et librement aux ateliers et formations de votre choix"
        )
        expect(content).not_to include("Vous devez obligatoirement prendre ce rendez-vous")
        expect(content).not_to include(
          "En l'absence d'action de votre part, vous risquez une suspension ou réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is rsa_atelier_competences" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_atelier_competences) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Participation à un atelier dans le cadre de votre RSA"
        )
        expect(content).to include(
          "Pour en profiter au mieux, nous vous invitons à vous inscrire directement" \
          " et librement aux ateliers et formations de votre choix"
        )
        expect(content).not_to include("Vous devez obligatoirement prendre ce rendez-vous")
        expect(content).not_to include(
          "En l'absence d'action de votre part, vous risquez une suspension ou réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is rsa_atelier_rencontres_pro" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_atelier_rencontres_pro) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Participation à un atelier dans le cadre de votre RSA"
        )
        expect(content).to include(
          "Pour en profiter au mieux, nous vous invitons à vous inscrire directement" \
          " et librement aux ateliers et formations de votre choix"
        )
        expect(content).not_to include("Nous vous remercions de prendre ce rendez-vous")
        expect(content).not_to include(
          "la sanction peut aller jusqu’à une suspension ou une réduction du versement de votre RSA."
        )
      end
    end

    context "when the context is rsa_orientation_on_phone_platform" do
      let!(:rdv_context) { create(:rdv_context, motif_category: category_rsa_orientation_on_phone_platform) }

      it "generates the pdf with the right content" do
        subject
        content = unescape_html(invitation.content)
        expect(content).to include(
          "Objet : Rendez-vous d’orientation dans le cadre de votre RSA"
        )
        expect(content).to include(
          "La première étape est <span class=\"bold-blue\">un appel téléphonique avec un professionnel de l’insertion" \
          "</span> afin de définir, selon votre situation et vos besoins, quelle sera la structure la " \
          "mieux adaptée pour vous accompagner."
        )
        expect(content).to include("Cet appel est obligatoire dans le cadre du versement de votre allocation RSA")
      end
    end
  end
end
