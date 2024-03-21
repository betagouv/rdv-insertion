require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RdvInsertion
  class Application < Rails::Application
    # Initialize category_configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.autoload_paths += Dir[Rails.root.join("app/models/concerns/validators")]
    # Settings in config/environments/* take precedence over those specified here.
    # Application category_configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = "Paris"
    config.i18n.available_locales = [:fr, :en]
    config.i18n.default_locale = :fr
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    config.exceptions_app = routes
    config.active_storage.draw_routes = false if Rails.env.production?

    # The following keys are generated using the following command:
    # bundle exec rails db:encryption:init
    #
    # These generated values are 32 bytes in length.
    # If you generate these yourself, the minimum lengths you should use are 12 bytes for the primary key
    # (this will be used to derive the AES 32 bytes key) and 20 bytes for the salt.
    #
    # See: https://guides.rubyonrails.org/active_record_encryption.html
    #
    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_KEY_DERIVATION_SALT"]
    config.active_record.encryption.extend_queries = true

    # Temporary support for unencrypted data during the migration process
    # Must be disabled once the migration is complete
    config.active_record.encryption.support_unencrypted_data = true

    config.active_storage.variant_processor = :image_processing
  end
end
