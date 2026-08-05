# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it directly.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false if config.respond_to?(:enable_reloading=)

  # Eager loading loads your full application so that your test suite runs
  # faster. Instead, take advantage of the lazy loading behavior of Rails
  # by only loading the specific class under test.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecations = %w[]

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation_warnings = %w[]

  # Tell Active Support to deprecate methods inline for faster test runs.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecations = %w[]

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation_warnings = %w[]

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise errors for missing migrations
  config.active_record.migration_error = :page_load
end
