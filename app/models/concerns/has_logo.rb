module HasLogo
  extend ActiveSupport::Concern
  ACCEPTED_FORMATS = %w[PNG JPG].freeze

  MIME_TYPES = [
    "image/png",
    "image/jpeg"
  ].freeze

  included do
    has_one_attached :logo
    validates :logo, max_size: 2.megabytes,
                     accepted_formats: { formats: ACCEPTED_FORMATS, mime_types: MIME_TYPES }
  end
end
