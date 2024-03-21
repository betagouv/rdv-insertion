FactoryBot.define do
  factory :follow_up do
    user
    motif_category

    after(:build) do |follow_up|
      # https://github.com/thoughtbot/factory_bot/issues/931#issuecomment-307542965
      follow_up.class.skip_callback(:save, :before, :set_status, raise: false) if follow_up.status.present?
    end
  end
end
