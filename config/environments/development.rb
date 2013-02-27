Sanataro::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
#  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.default_url_options = { :host => "127.0.0.1:3000" }
  config.action_mailer.delivery_method = :sendmail

  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  unless defined?(JRUBY_VERSION)
    config.active_record.auto_explain_threshold_in_seconds = 0.5
  end

  config.assets.compress = false
  # Expands the lines which load the assets
  config.assets.debug = true

  config.cache_store = :null_store
  # config.cache_store = :memory_store
  # config.cache_store = :dalli_store
end
