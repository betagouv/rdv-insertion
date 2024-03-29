FactoryBot.define do
  factory :file_configuration do
    sequence(:sheet_name) { |n| "LISTE DEMANDEURS_#{n}" }
    role_column { "Rôle" }
    email_column { "Adresses Mails" }
    title_column { "Civilité" }
    last_name_column { "Nom bénéficiaire" }
    birth_date_column { "Date de naissance" }
    first_name_column { "Prénom bénéficiaire" }
    address_first_field_column { "Adresse" }
    address_second_field_column { "Complement Destinataire" }
    address_third_field_column { "Complément lieu" }
    address_fourth_field_column { "CP" }
    address_fifth_field_column { "Commune" }
    phone_number_column { "N° Téléphones" }
    referent_email_column { "Référent" }
    affiliation_number_column { "N° CAF" }
    france_travail_id_column { "ID FT" }
    nir_column { "NIR" }
  end
end
