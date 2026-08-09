source "https://rubygems.org"

ruby ">= 3.3.0"

# Core
gem "rails", "~> 7.1.0"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"

# Authentication
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 2.7"

# Background Jobs
gem "sidekiq", "~> 7.2"
gem "redis", "~> 5.0"

# API
gem "rack-cors", "~> 2.0"

# Rate Limiting
gem "rack-attack", "~> 6.7"

# Serialization
gem "active_model_serializers", "~> 0.10"

# Development & Testing
group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "listen", "~> 3.3"
end

group :test do
  gem "shoulda-matchers", "~> 5.3"
  gem "simplecov", require: false
  gem "webmock", "~> 3.19"
end

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
