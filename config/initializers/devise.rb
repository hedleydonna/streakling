# frozen_string_literal: true

Devise.setup do |config|
  # Mailer
  config.mailer_sender = 'hello@streakling.onrender.com'

  # ORM
  require 'devise/orm/active_record'

  # Case & whitespace
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # Session storage
  config.skip_session_storage = [:http_auth]

  # Password
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Confirmable
  config.reconfirmable = true

  # Rememberable
  config.expire_all_remember_me_on_sign_out = true

  # Recoverable
  config.reset_password_within = 6.hours

  # Sign out method
  config.sign_out_via = :delete

  # HOTWIRE/TURBO FIX – THIS IS THE REAL SOLUTION
  config.responder.error_status = :unprocessable_entity   # returns 422 instead of 200
  config.responder.redirect_status = :see_other           # returns 303 instead of 302

  # (Everything else uses defaults – no need to touch)
end
