require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes                     = true
  config.eager_load                        = true
  config.consider_all_requests_local       = false
  config.public_file_server.enabled        = true
  config.force_ssl                         = false

  # ← THESE TWO LINES FIXED (no syntax error)
  config.action_controller.default_url_options = { host: "streakling.onrender.com", protocol: "https" }
  config.action_mailer.default_url_options     = { host: "streakling.onrender.com", protocol: "https" }

  # ← TEMPORARY NUCLEAR HOST WHITELIST (this is the magic that finally works)
  config.hosts.clear
  config.hosts << "streakling.onrender.com"
  config.hosts << "localhost"

  config.log_level = :info
  config.active_record.dump_schema_after_migration = false
end
