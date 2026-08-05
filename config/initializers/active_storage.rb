# frozen_string_literal: true

# Active Storage configuration for TaskFlow API
# Store files locally for development, use cloud storage in production

Rails.application.configure do
  if Rails.env.development?
    config.active_storage.service = :local
  elsif Rails.env.test?
    config.active_storage.service = :test
  else
    # In production, use cloud storage (S3, GCS, etc.)
    # config.active_storage.service = :amazon
    config.active_storage.service = :local
  end
end
