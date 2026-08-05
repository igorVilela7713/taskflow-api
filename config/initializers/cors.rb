# frozen_string_literal: true

# CORS configuration for TaskFlow API
# Configured to allow cross-origin requests

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization],
             max_age: 600
  end
end
