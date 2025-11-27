# config/initializers/relax_host_authorization.rb
# This is the standard, accepted Render fix for Rails 7.1+ blocked hosts
# It keeps the protection but excludes Render's own health-check & preview URLs

Rails.application.config.host_authorization = {
  exclude: ->(request) {
    request.path.start_with?("/up") ||           # Render health checks
    request.host.end_with?(".onrender.com") ||   # All Render domains
    request.host == "localhost" ||
    request.host == "127.0.0.1" ||
    request.host == "0.0.0.0"
  }
}
