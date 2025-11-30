# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Render handles HTTPS — we must NOT force it again
  config.force_ssl = false

  # Correct URLs for Devise redirects and mailers
  config.action_controller.default_url_options = { host:host => "streakling.onrender.com", :protocol => "https"}
  config.action_mailer.default_url_options     = { :host => "streakling.onrender.com", :protocol => "https" }

  # Host whitelisting
  config.hosts = [
    "streakling.onrender.com",
    /.*\.onrender\.com/,
    "localhost",
    "127.0.0.1",
    "0.0.0.0"
  ]

  # Assets & storage
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.active_storage.service = :local

  # Logging
  config.log_level = :info
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

  # Misc
  config.active_record.dump_schema_after_migration = false
  config.i18n.fallbacks = true
end
