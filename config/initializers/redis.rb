# frozen_string_literal: true

# Redis configuration for TaskFlow API
REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

REDIS = Redis.new(url: REDIS_URL)

# Configure Rails cache to use Redis
Rails.application.configure do
  config.cache_store = :redis_cache_store, {
    url: REDIS_URL,
    namespace: "taskflow_cache",
    expires_in: 5.minutes,
    pool_size: 5,
    pool_timeout: 5
  }
end
