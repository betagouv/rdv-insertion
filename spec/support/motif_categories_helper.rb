# rubocop:disable Metrics/ModuleLength
module MotifCategoriesHelper
  shared_context "with all existing categories" do
    let!(:category_rsa_orientation) do
      create(
        :motif_category,
        name: "RSA orientation", short_name: "rsa_orientation",
        leads_to_orientation: true,
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'orientation",
          rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_orientation_coaching) do
      create(
        :motif_category,
        name: "RSA orientation - coaching emploi", short_name: "rsa_orientation_coaching",
        leads_to_orientation: true,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'orientation",
          rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_orientation_freelance) do
      create(
        :motif_category,
        name: "RSA orientation - travailleurs indépendants", short_name: "rsa_orientation_freelance",
        leads_to_orientation: true,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'orientation",
          rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_accompagnement) do
      create(
        :motif_category,
        name: "RSA accompagnement",
        short_name: "rsa_accompagnement",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'accompagnement",
          rdv_title_by_phone: "rendez-vous d'accompagnement téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true,
          punishable_warning: "votre RSA pourra être suspendu ou réduit"
        )
      )
    end
    let!(:category_rsa_accompagnement_sociopro) do
      create(
        :motif_category,
        name: "RSA accompagnement socio-pro",
        short_name: "rsa_accompagnement_sociopro",
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'accompagnement",
          rdv_title_by_phone: "rendez-vous d'accompagnement téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true,
          punishable_warning: "votre RSA pourra être suspendu ou réduit"
        )
      )
    end
    let!(:category_rsa_accompagnement_social) do
      create(
        :motif_category,
        name: "RSA accompagnement social",
        short_name: "rsa_accompagnement_social",
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'accompagnement",
          rdv_title_by_phone: "rendez-vous d'accompagnement téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true,
          punishable_warning: "votre RSA pourra être suspendu ou réduit"
        )
      )
    end
    let!(:category_rsa_cer_signature) do
      create(
        :motif_category,
        name: "RSA signature CER",
        short_name: "rsa_cer_signature",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous de signature de CER",
          rdv_title_by_phone: "rendez-vous téléphonique de signature de CER",
          rdv_purpose: "construire et signer votre Contrat d'Engagement Réciproque",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_follow_up) do
      create(
        :motif_category,
        name: "RSA suivi",
        short_name: "rsa_follow_up",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous de suivi",
          rdv_title_by_phone: "rendez-vous de suivi téléphonique",
          rdv_purpose: "faire un point avec votre référent de parcours",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_rsa_insertion_offer) do
      create(
        :motif_category,
        name: "RSA offre insertion pro",
        short_name: "rsa_insertion_offer",
        leads_to_orientation: true,
        optional_rdv_subscription: true,
        template: create(
          :template,
          model: "atelier",
          rdv_title: "atelier",
          rdv_title_by_phone: "atelier téléphonique",
          rdv_subject: "RSA",
          user_designation: "bénéficiaire du RSA",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_rsa_orientation_on_phone_platform) do
      create(
        :motif_category,
        name: "RSA orientation sur plateforme téléphonique",
        short_name: "rsa_orientation_on_phone_platform",
        leads_to_orientation: true,
        template: create(
          :template,
          model: "phone_platform",
          rdv_title: "rendez-vous d'orientation téléphonique",
          rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
          rdv_subject: "RSA",
          user_designation: "bénéficiaire du RSA",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_atelier_collectif_mandatory) do
      create(
        :motif_category,
        name: "RSA Atelier collectif obligatoire",
        short_name: "rsa_atelier_collectif_mandatory",
        template: create(
          :template,
          model: "standard",
          rdv_title: "atelier collectif",
          rdv_title_by_phone: "atelier collectif",
          rdv_purpose: "vous aider dans votre parcours d'insertion",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_atelier_rencontres_pro) do
      create(
        :motif_category,
        name: "RSA Atelier rencontres professionnelles",
        short_name: "rsa_atelier_rencontres_pro",
        optional_rdv_subscription: true,
        template: create(
          :template,
          model: "atelier",
          rdv_title: "atelier",
          rdv_title_by_phone: "atelier téléphonique",
          rdv_subject: "RSA",
          user_designation: "bénéficiaire du RSA",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_rsa_atelier_competences) do
      create(
        :motif_category,
        name: "RSA Atelier compétences",
        short_name: "rsa_atelier_competences",
        optional_rdv_subscription: true,
        template: create(
          :template,
          model: "atelier",
          rdv_title: "atelier",
          rdv_title_by_phone: "atelier téléphonique",
          rdv_subject: "RSA",
          user_designation: "bénéficiaire du RSA",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_rsa_main_tendue) do
      create(
        :motif_category,
        name: "RSA Main Tendue",
        short_name: "rsa_main_tendue",
        template: create(
          :template,
          model: "standard",
          rdv_title: "entretien de main tendue",
          rdv_title_by_phone: "entretien téléphonique de main tendue",
          rdv_purpose: "faire le point sur votre situation",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_rsa_spie) do
      create(
        :motif_category,
        name: "RSA SPIE",
        short_name: "rsa_spie",
        leads_to_orientation: true,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'accompagnement",
          rdv_title_by_phone: "rendez-vous d'accompagnement téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "demandeur d'emploi",
          rdv_subject: "demande d'emploi",
          display_mandatory_warning: true,
          punishable_warning: "votre RSA pourra être suspendu ou réduit"
        )
      )
    end
    let!(:category_rsa_integration_information) do
      create(
        :motif_category,
        name: "RSA Information d'intégration",
        short_name: "rsa_integration_information",
        leads_to_orientation: true,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'information",
          rdv_title_by_phone: "rendez-vous d'information téléphonique",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          rdv_purpose: "vous renseigner sur vos droits et vos devoirs",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_psychologue) do
      create(
        :motif_category,
        name: "Psychologue",
        short_name: "psychologue",
        template: create(
          :template,
          model: "short",
          rdv_title: "rendez-vous de suivi psychologue",
          rdv_title_by_phone: "rendez-vous téléphonique de suivi psychologue",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_rsa_orientation_france_travail) do
      create(
        :motif_category,
        name: "RSA orientation France Travail",
        short_name: "rsa_orientation_france_travail",
        leads_to_orientation: true,
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous d'orientation",
          rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
          rdv_purpose: "démarrer un parcours d'accompagnement",
          user_designation: "bénéficiaire du RSA",
          rdv_subject: "RSA",
          custom_sentence: "Dans le cadre du projet 'France Travail', ce rendez-vous sera réalisé par deux" \
                           " professionnels de l’insertion (l’un de Pôle emploi, l’autre du Conseil départemental)" \
                           " et permettra de mieux comprendre votre situation afin de vous proposer" \
                           " un accompagnement adapté",
          display_mandatory_warning: true
        )
      )
    end
    let!(:category_atelier_enfants_ados) do
      create(
        :motif_category,
        name: "Atelier Enfants / Ados",
        short_name: "atelier_enfants_ados",
        template: create(
          :template,
          model: "atelier_enfants_ados",
          rdv_title: "atelier destiné aux jeunes de ton âge",
          rdv_title_by_phone: "atelier téléphonique destiné aux jeunes de ton âge",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_siae_interview) do
      create(
        :motif_category,
        name: "Entretien SIAE",
        short_name: "siae_interview",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "entretien d'embauche",
          rdv_title_by_phone: "entretien d'embauche téléphonique",
          user_designation: "candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)",
          rdv_subject: "candidature SIAE",
          rdv_purpose: "poursuivre le processus de recrutement",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_siae_collective_information) do
      create(
        :motif_category,
        name: "Info coll. SIAE",
        short_name: "siae_collective_information",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous collectif d'information",
          rdv_title_by_phone: "rendez-vous collectif d'information téléphonique",
          user_designation: "candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)",
          rdv_subject: "candidature SIAE",
          rdv_purpose: "découvrir cette structure",
          display_mandatory_warning: false
        )
      )
    end
    let!(:category_siae_follow_up) do
      create(
        :motif_category,
        name: "Suivi SIAE",
        short_name: "siae_follow_up",
        optional_rdv_subscription: false,
        template: create(
          :template,
          model: "standard",
          rdv_title: "rendez-vous de suivi",
          rdv_title_by_phone: "rendez-vous de suivi téléphonique",
          user_designation: "salarié.e au sein de notre structure",
          rdv_subject: "suivi SIAE",
          rdv_purpose: "faire un point avec votre référent",
          display_mandatory_warning: false
        )
      )
    end
  end
end
# rubocop:enable Metrics/ModuleLength
