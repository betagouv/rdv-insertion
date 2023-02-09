FactoryBot.define do
  factory :configuration do
    association :motif_category
    association :file_configuration
    invitation_formats { %w[sms] }
  end
end
