# frozen_string_literal: true

# This file is used to start up a Rails server
# It's a simplified version for API-only mode

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TaskflowApi
  class Application < Rails::Application
    config.load_defaults 7.1

    # Use API-only mode
    config.api_only = true

    # Enable cache for API
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
      namespace: "taskflow_cache",
      expires_in: 5.minutes
    }

    # Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*",
                 headers: :any,
                 methods: %i[get post put patch delete options head],
                 expose: %w[Authorization]
      end
    end
  end
end
