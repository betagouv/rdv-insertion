FactoryBot.define do
  factory :category_configuration do
    organisation
    motif_category
    file_configuration
    invitation_formats { %w[sms email postal] }
    phone_number { "0101010101" }
  end
end
