FactoryBot.define do
  factory :participation do
    user
    rdv
    follow_up
    sequence(:rdv_solidarites_participation_id)

    after(:build) do |participation|
      participation.status = participation.rdv.status if participation.status.blank?
      participation.created_by = (participation.rdv.created_by || "user") if participation.created_by.blank?
    end
  end
end
