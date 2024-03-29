FactoryBot.define do
  factory :messages_configuration do
    direction_names do
      ["DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX",
       "DIRECTION DE L’INSERTION ET DU RETOUR À L’EMPLOI",
       "SERVICE ORIENTATION ET ACCOMPAGNEMENT VERS L’EMPLOI"]
    end
    sms_sender_name { "Rdvi" }
  end
end
