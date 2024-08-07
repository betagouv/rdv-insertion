source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.3"

# Environment variables management
gem "dotenv-rails"
# Policies management
gem "pundit"
# Http client
gem "faraday"
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", ">= 6.0.4.1"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "< 7"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"

# JavaScript Bundling for Rails
gem "jsbundling-rails"

# Easy use of react with rails
gem "react-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"

gem "responders"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# AR Pagination
gem "kaminari"
# PG search
gem "pg_search"
# Adds advisory locking (mutexes)
gem "with_advisory_lock"

# CSS styled emails with stylesheets
gem "premailer-rails"

# API documentation
gem "rswag"

# Send SMS & emails with Brevo
gem "sib-api-v3-sdk"

# Queuing system
gem "sidekiq"

# Job scheduling
gem "sidekiq-cron"

# Hotwire
gem "turbo-rails"

# Monitor errors
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

# JSON web token
gem "jwt"

# Phone validator
gem "phonelib"

# Stats graphs
gem "groupdate"
gem "chartkick"

# generate QR codes
gem "rqrcode", "~> 2.0", require: false

# gem needed to be defined explicitely with ruby 3
gem "rexml"
gem "addressable"

gem "agent_connect", git: "https://github.com/gip-inclusion/agent_connect_engine"

# Easily generate PDF from HTML
gem "wicked_pdf"
gem "wkhtmltopdf-binary"

# CORS support
gem "rack-cors"

# Sending ZIP
gem "rubyzip"

# Simple Fast Declarative Serialization Library
gem "blueprinter"

# A Rails engine for creating super-flexible admin dashboards
gem "administrate", git: "https://github.com/thoughtbot/administrate.git"

# manage attachments from administrate dashboards
gem "administrate-field-active_storage"

# Use Active Storage variant
gem "image_processing"

# Required for ActiveStorage for S3 compatible storage
gem "aws-sdk-s3", require: false

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

# APM
gem "skylight"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "prosopite"
  gem "pg_query"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring", "~> 3.0.0"
  gem "letter_opener_web" # Preview email in the default browser instead of sending it.
  gem "rails-erd"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver", "~> 4.4"
  gem "pdf-reader"
  gem "rack_session_access"
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
