require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Core settings
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled        = true
  config.assets.compile                    = false
  config.active_storage.service           = :local

  # THIS IS THE FIX THAT KILLS THE REDIRECT LOOP
  config.force_ssl = false

  # Tell Rails + Devise the correct host/protocol (Render handles HTTPS)
  config.action_controller.default_url_options = { host: "streakling.onrender.com", protocol: "https" }
  config.action_mailer.default_url_options     = { host: "streakling.onrender.com", protocol: "https" }

  # Host whitelisting — required for Rails 7+
  config.hosts = [
    "streakling.onrender.com",
    /.*\.onrender\.com/,
    "localhost",
    "127.0.0.1",
    "0.0.0.0"
  ]

  # Logging
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Misc
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
