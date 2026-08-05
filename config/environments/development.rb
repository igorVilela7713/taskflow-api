# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Enable code reloading for development
  config.enable_reloading = true if Rails.env.development?

  # Do not eager load code on boot in development
  config.eager_load = false

  # Show full error reports in development
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching
  if Rails.env.development?
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local if Rails.env.development?

  # Don't care if the mailer can't send in development
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations
  config.active_support.disallowed_deprecations = %w[]

  # Raise exceptions for disallowed deprecations
  config.active_support.disallowed_deprecation_warnings = %w[]

  # Raise errors for missing migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation, preprocessing and optimization of assets
  config.assets.debug = true

  # Suppress logger output for asset requests
  config.assets.quiet = true

  # Raise on Unknown Ligatures
  config.active_job.verbose_enqueue_logs = true if Rails.env.development?
end
