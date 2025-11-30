require "active_support/core_ext/integer/time"

Rails.application.configure do
  # basic production settings
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.assets.compile = false
  config.active_storage.service = :local

  # THIS IS THE ONLY THING THAT MATTERS RIGHT NOW
  config.force_ssl = false                                   # ← kills the loop
  config.public_file_server.enabled = true                  # serve assets

  # tell Rails + Devise the correct host/protocol for URLs
  config.action_controller.default_url_options = { host: "streakling.onrender.com", protocol: "https" }
  config.action_mailer.default_url_options     = { host: "streakling.onrender.com", protocol: "https" }

  # proper host whitelisting (no more Blocked hosts)
  config.hosts = [
    "streakling.onrender.com",
    /.*\.onrender\.com/,
    "localhost",
    "127.0.0.1",
    "0.0.0.0"
  ]

  # logging
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # misc
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
