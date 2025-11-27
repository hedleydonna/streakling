# config/initializers/disable_host_authorization.rb
# THIS IS THE NUCLEAR FIX FOR RENDER'S BLOCKED HOSTS ISSUE
# It completely disables ActionDispatch::HostAuthorization in production
# Safe for now — we'll remove it when we have a custom domain

Rails.application.config.middleware.delete ActionDispatch::HostAuthorization

# Optional: just in case, also clear the hosts list
Rails.application.config.hosts = nil
