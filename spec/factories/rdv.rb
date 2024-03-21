FactoryBot.define do
  factory :rdv do
    sequence(:uuid) { SecureRandom.uuid }
    sequence(:rdv_solidarites_rdv_id)
    starts_at { 3.days.from_now }
    duration_in_min { 30 }
    organisation
    motif
    status { "unknown" }
    created_by { "user" }
    address { "2O avenue de Ségur, 75007 Paris" }
    lieu
    agents { [create(:agent)] }

    after(:build) do |rdv|
      if rdv.participations.blank?
        rdv.users = [create(:user)]
        rdv.participations.first.follow_up = create(:follow_up)
        rdv.participations.first.created_by = "user"
      end
    end
  end
end
