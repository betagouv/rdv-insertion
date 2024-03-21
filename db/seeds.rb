# Rappel : rdv-solidarités doit être installé et tourner en local pour obtenir un environnement de dev fonctionnel
# Le code de rdv-solidarités peut être trouvé ici : https://github.com/betagouv/rdv-solidarites.fr/
# Il n'y a pas d'agent créé ici : les agents utilisateurs de rdv-insertion sont récupérés de rdv-solidarités

# Pour utiliser rdv-insertion proprement en local, en plus de ces seeds, il est nécessaire de créer sur rdv-s :
# - les territories et organisations correspondant aux départments et organisations créés ci-dessous
# - rattacher l'agent aux organisations via un AgentRole (access_level: "admin")
# - configurer les webhooks de chaque organisation

# Les seeds de rdv-solidarités permettent de créer ces différents éléments
# L'agent à utiliser est alors "Alain Sertion"
  # email: "alain.sertion@rdv-insertion-demo.fr",
  # password: "123456",
# Les rdv_solidarites_organisation_id sont configurées pour match ces seeds, mais il est préférable de les vérifier



# --------------------------------------------------------------------------------------------------------------------
puts "Creating departments..."
# La Drôme permet de tester plusieurs organisations, plusieurs contextes et tous les formats d'invitation
drome = Department.create!(
  name: "Drôme",
  number: "26",
  capital: "Valence",
  region: "Auvergne-Rhône-Alpes",
  pronoun: "la",
)

# Dans l'Yonne, pas de système d'invitation : les bénéficiaires sont directement convoqués (convene_user: true)
yonne = Department.create!(
  name: "Yonne",
  number: "89",
  capital: "Auxerre",
  region: "Bourgogne-Franche-Comté",
  pronoun: "l'",
)

# --------------------------------------------------------------------------------------------------------------------
puts "Creating motif categories..."
orientation_category = MotifCategory.create!(
  short_name: "rsa_orientation", name: "RSA orientation",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "rendez-vous d'orientation",
    rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
    rdv_purpose: "démarrer un parcours d'accompagnement",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    display_mandatory_warning: true
  )
)
accompagnement_category = MotifCategory.create!(
  short_name: "rsa_accompagnement", name: "RSA accompagnement",
  template: Template.find_or_create_by!(
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
MotifCategory.create!(
  name: "RSA accompagnement socio-pro",
  short_name: "rsa_accompagnement_sociopro",
  template: Template.find_or_create_by!(
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
MotifCategory.create!(
  name: "RSA accompagnement social",
  short_name: "rsa_accompagnement_social",
  template: Template.find_or_create_by!(
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
MotifCategory.create!(
  name: "RSA signature CER",
  short_name: "rsa_cer_signature",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "rendez-vous de signature de CER",
    rdv_title_by_phone: "rendez-vous téléphonique de signature de CER",
    rdv_purpose: "construire et signer votre Contrat d'Engagement Réciproque",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    display_mandatory_warning: true
  )
)
MotifCategory.create!(
  name: "RSA suivi",
  short_name: "rsa_follow_up",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "rendez-vous de suivi",
    rdv_title_by_phone: "rendez-vous de suivi téléphonique",
    rdv_purpose: "faire un point avec votre référent de parcours",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    display_mandatory_warning: false,
  )
)
MotifCategory.create!(
  name: "RSA offre insertion pro",
  short_name: "rsa_insertion_offer",
  optional_rdv_subscription: true,
  template: Template.find_or_create_by!(
    model: "atelier",
    rdv_title: "atelier",
    rdv_title_by_phone: "atelier téléphonique",
    rdv_subject: "RSA",
    user_designation: "bénéficiaire du RSA"
  )
)

MotifCategory.create!(
  name: "RSA orientation sur plateforme téléphonique",
  short_name: "rsa_orientation_on_phone_platform",
  template: Template.find_or_create_by!(
    model: "phone_platform",
    rdv_title: "rendez-vous d'orientation téléphonique",
    rdv_title_by_phone: "rendez-vous d'orientation téléphonique",
    rdv_subject: "RSA",
    user_designation: "bénéficiaire du RSA",
    rdv_purpose: "démarrer un parcours d'accompagnement"
  )
)
MotifCategory.create!(
  name: "RSA Atelier collectif obligatoire",
  short_name: "rsa_atelier_collectif_mandatory",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "atelier collectif",
    rdv_title_by_phone: "atelier collectif",
    rdv_purpose: "vous aider dans votre parcours d'insertion",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    display_mandatory_warning: true
  )
)
MotifCategory.create!(
  name: "RSA Atelier rencontres professionnelles",
  short_name: "rsa_atelier_rencontres_pro",
  optional_rdv_subscription: true,
  template: Template.find_or_create_by!(
    model: "atelier",
    rdv_title: "atelier",
    rdv_title_by_phone: "atelier téléphonique",
    rdv_subject: "RSA",
    user_designation: "bénéficiaire du RSA"
  )
)
MotifCategory.create!(
  name: "RSA Atelier compétences",
  short_name: "rsa_atelier_competences",
  optional_rdv_subscription: true,
  template: Template.find_or_create_by!(
    model: "atelier",
    rdv_title: "atelier",
    rdv_title_by_phone: "atelier téléphonique",
    rdv_subject: "RSA",
    user_designation: "bénéficiaire du RSA"
  )
)
MotifCategory.create!(
  name: "RSA Main Tendue",
  short_name: "rsa_main_tendue",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "entretien de main tendue",
    rdv_title_by_phone: "entretien téléphonique de main tendue",
    rdv_purpose: "faire le point sur votre situation",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    display_mandatory_warning: true
  )
)
MotifCategory.create!(
  name: "RSA SPIE",
  short_name: "rsa_spie",
  template: Template.find_or_create_by!(
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
MotifCategory.create!(
  name: "RSA Information d'intégration",
  short_name: "rsa_integration_information",
  template: Template.find_or_create_by!(
    model: "standard",
    rdv_title: "rendez-vous d'information",
    rdv_title_by_phone: "rendez-vous d'information téléphonique",
    user_designation: "bénéficiaire du RSA",
    rdv_subject: "RSA",
    rdv_purpose: "vous renseigner sur vos droits et vos devoirs",
    display_mandatory_warning: true
  )
)

# --------------------------------------------------------------------------------------------------------------------
puts "Creating file category_configurations..."
file_config_drome = FileConfiguration.create(
  sheet_name: "ENTRETIENS PHYSIQUES",
  address_first_field_column: "Adresse",
  last_name_column: "Nom bénéficiaire",
  first_name_column: "Prénom bénéficiaire",
  email_column: "Adresses Mails",
  birth_date_column: "Date de Naissance",
  address_fifth_field_column: "CP Ville",
  affiliation_number_column: "N° CAF",
  role_column: "Rôle",
  phone_number_column: "N° Téléphones",
  title_column: "Civilité",
  department_internal_id_column: "ID Iodas"
)

file_config_yonne = FileConfiguration.create(
  sheet_name: "Feuille1",
  affiliation_number_column: "N° CAF",
  last_name_column: "Nom",
  first_name_column: "Prénom",
  phone_number_column: "Numéro(s) de téléphone",
  address_first_field_column: "Adresse",
  birth_date_column: "Date de naissance",
  role_column: "Rôle",
  title_column: "Civilité",
  birth_name_column: "Nom JF",
  department_internal_id_column: "Code individu Iodas"
)

# --------------------------------------------------------------------------------------------------------------------
puts "Creating organisations and category_configurations..."
drome1_organisation = Organisation.create!(
  name: "Plateforme mutualisée d'orientation",
  phone_number: "0475796991",
  rdv_solidarites_organisation_id: 1,
  # rdv_solidarites_organisation_id: vérifier l'id de l'organisation correspondante sur RDV-Solidarites
  department_id: drome.id
)

Configuration.create!(
  file_configuration: file_config_drome,
  convene_user: false,
  invitation_formats: ["sms", "email", "postal"],
  motif_category: orientation_category,
  number_of_days_before_action_required: 10,
  organisation: drome1_organisation
)

Configuration.create!(
  file_configuration: file_config_drome,
  convene_user: false,
  invitation_formats: ["sms", "email", "postal"],
  motif_category: accompagnement_category,
  number_of_days_before_action_required: 10,
  organisation: drome1_organisation
)

MessagesConfiguration.create!(
  direction_names:
    ["DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX",
    "DIRECTION DE L’INSERTION ET DU RETOUR À L’EMPLOI",
    "SERVICE ORIENTATION ET ACCOMPAGNEMENT VERS L’EMPLOI"],
  organisation: drome1_organisation
)

drome2_organisation = Organisation.create!(
  name: "PLIE Valence",
  phone_number: "0101010102",
  rdv_solidarites_organisation_id: 2,
  # rdv_solidarites_organisation_id: vérifier l'id de l'organisation correspondante sur RDV-Solidarites
  department_id: drome.id
)

Configuration.create!(
  file_configuration: file_config_drome,
  convene_user: false,
  invitation_formats: ["sms", "email", "postal"],
  motif_category: orientation_category,
  number_of_days_before_action_required: 10,
  organisation: drome2_organisation
)

Configuration.create!(
  file_configuration: file_config_drome,
  convene_user: false,
  invitation_formats: ["sms", "email", "postal"],
  motif_category: accompagnement_category,
  number_of_days_before_action_required: 10,
  organisation: drome2_organisation
)

MessagesConfiguration.create!(
  direction_names:
    ["DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX",
    "DIRECTION DE L’INSERTION ET DU RETOUR À L’EMPLOI",
    "SERVICE ORIENTATION ET ACCOMPAGNEMENT VERS L’EMPLOI"],
  organisation: drome2_organisation
)

yonne_organisation = Organisation.create!(
  name: "UT Avallon",
  phone_number: "0303030303",
  rdv_solidarites_organisation_id: 3,
  # rdv_solidarites_organisation_id: vérifier l'id de l'organisation correspondante sur RDV-Solidarites
  department_id: yonne.id
)

Configuration.create!(
  file_configuration: file_config_yonne,
  convene_user: true,
  invitation_formats: [],
  motif_category: orientation_category,
  number_of_days_before_action_required: 10,
  organisation: yonne_organisation
)

MessagesConfiguration.create!(
  direction_names:
    ["DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX",
    "DIRECTION DE L’INSERTION ET DU RETOUR À L’EMPLOI",
    "SERVICE ORIENTATION ET ACCOMPAGNEMENT VERS L’EMPLOI"],
  organisation: yonne_organisation
)

# --------------------------------------------------------------------------------------------------------------------
puts "Creating agent and motifs..."
# Faking Webhooks entries (for avoiding resending them from rdv solidarites manually), update ids from rdv-s if rdv solidarite seed is changing

agent = Agent.create!(
  email: "alain.sertion@rdv-insertion-demo.fr",
  rdv_solidarites_agent_id: 1,
  # rdv_solidarites_agent_id: vérifier l'id de l'agent correspondant sur RDV-Solidarites
  first_name: "Alain",
  last_name: "Sertion",
  last_sign_in_at: Time.zone.now,
  last_webhook_update_received_at: Time.zone.now
)

agent.organisations << drome1_organisation
agent.organisations << drome2_organisation
agent.organisations << yonne_organisation
agent.save!

Motif.create!(
  rdv_solidarites_motif_id: 1,
  # rdv_solidarites_motif_id: vérifier l'id du motif correspondant sur RDV-Solidarites
  name: "RSA - Orientation : rdv sur site",
  reservable_online: true,
  rdv_solidarites_service_id: 1,
  # rdv_solidarites_service_id: vérifier l'id du service correspondant sur RDV-Solidarites
  collectif: false,
  location_type: "public_office",
  motif_category: orientation_category,
  last_webhook_update_received_at: Time.zone.now,
  organisation_id: drome1_organisation.id,
  follow_up: false
)

Motif.create!(
  rdv_solidarites_motif_id: 2,
  # rdv_solidarites_motif_id: vérifier l'id du motif correspondant sur RDV-Solidarites
  name: "RSA accompagnement",
  reservable_online: true,
  deleted_at: nil,
  rdv_solidarites_service_id: 1,
  # rdv_solidarites_service_id: vérifier l'id du service correspondant sur RDV-Solidarites
  collectif: false,
  location_type: "public_office",
  motif_category: accompagnement_category,
  last_webhook_update_received_at: Time.zone.now,
  organisation_id: drome1_organisation.id,
  follow_up: false
)

Motif.create!(
  rdv_solidarites_motif_id: 3,
  # rdv_solidarites_motif_id: vérifier l'id du motif correspondant sur RDV-Solidarites
  name: "RSA - Orientation : rdv sur site",
  reservable_online: true,
  deleted_at: nil,
  rdv_solidarites_service_id: 1,
  # rdv_solidarites_service_id: vérifier l'id du service correspondant sur RDV-Solidarites
  collectif: false,
  location_type: "public_office",
  motif_category: orientation_category,
  last_webhook_update_received_at: Time.zone.now,
  organisation_id: drome2_organisation.id,
  follow_up: false
)

Motif.create!(
  rdv_solidarites_motif_id: 4,
  # rdv_solidarites_motif_id: vérifier l'id du motif correspondant sur RDV-Solidarites
  name: "RSA - Codiagnostic d'orientation",
  reservable_online: false,
  deleted_at: nil,
  rdv_solidarites_service_id: 1,
  # rdv_solidarites_service_id: vérifier l'id du service correspondant sur RDV-Solidarites
  collectif: false,
  location_type: "public_office",
  motif_category: orientation_category,
  last_webhook_update_received_at: Time.zone.now,
  organisation_id: yonne_organisation.id,
  follow_up: false
)

Motif.create!(
  rdv_solidarites_motif_id: 5,
  # rdv_solidarites_motif_id: vérifier l'id du motif correspondant sur RDV-Solidarites
  name: "RSA - Orientation : rdv téléphonique",
  reservable_online: false,
  deleted_at: nil,
  rdv_solidarites_service_id: 1,
  # rdv_solidarites_service_id: vérifier l'id du service correspondant sur RDV-Solidarites
  collectif: false,
  location_type: "phone",
  motif_category: orientation_category,
  last_webhook_update_received_at: Time.zone.now,
  organisation_id: yonne_organisation.id,
  follow_up: false
)

puts "Done!"
