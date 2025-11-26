source "https://rubygems.org"
# ruby "2.7.4"  # Render uses 2.7.8

gem "rails", "~> 7.1.6"
gem "sprockets-rails"
gem "pg", "~> 1.5.0"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 0.4.1"
gem "jbuilder"
gem "bootsnap", ">= 1.4.4", require: false, group: :default

# Our three magic gems — MUST be here, not at the bottom
gem 'devise'
gem 'hotwire-rails', github: 'hotwired/hotwire-rails', branch: 'main'
gem 'pay', github: 'pay-rails/pay'

# Remove or comment this line — Render sees it and freaks out
# gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

group :development, :test do
  # (debug gem removed earlier)
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
