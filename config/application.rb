# coding: utf-8

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Kakeibo3
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
     config.active_record.observers = :item_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    config.generators do |g|
      g.test_framework      :rspec, :fixture => true
      g.fixture_replacement :fabrication
    end
  end
end

PRODUCT_NAME='家計簿 さな太郎'
CREDIT_RELATION_SETTLEMENT_DAYS = CREDIT_RELATION_PAYMENT_DAYS = [['1', 1], ['2', 2], ['3', 3], ['4', 4], ['5', 5], ['6', 6], ['7', 7], ['8', 8], ['9', 9], ['10', 10], ['11', 11], ['12', 12], ['13', 13], ['14', 14], ['15', 15], ['16', 16], ['17', 17], ['18', 18], ['19', 19], ['20', 20], ['21', 21], ['22', 22], ['23', 23], ['24', 24], ['25', 25], ['26', 26], ['27', 27], ['28', 28], ['末日', 99]]
CREDIT_RELATION_PAYMENT_MONTHS =  [['同月', 0], ['翌月', 1], ['翌々月', 2], ['翌々々月', 3]]
ActionMailer::Base.delivery_method = :sendmail
SYSTEM_MAIL_ADDRESS = "donotreply@nu-chon.org"
HIGHLIGHT_DURATION = '1.0'
PULSATE_DURATION = 300
PULSATE_TIMES = 3
FADE_DURATION = 300

