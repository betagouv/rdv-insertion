FactoryBot.define do
  factory :organisation do
    sequence(:name) { |n| "Departement n°#{n}" }
    sequence(:rdv_solidarites_organisation_id)
    department { create(:department) }
  end
end
