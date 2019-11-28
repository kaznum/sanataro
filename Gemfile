# frozen_string_literal: true

source 'http://rubygems.org'

###
### This file is for MRI
### Please see gemfiles/Gemfile.jruby for JRuby env
###

gem 'rails', '~> 5.2.1'

# Use unicorn as the web server
# gem 'unicorn'

group :development, :test do
  gem 'fabrication'
  gem 'haml_lint', require: false
  gem 'launchy'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '>= 2.13.1'
  unless ENV['TRAVIS']
    if RUBY_VERSION >= '2.0.0'
      gem 'byebug'
    else
      gem 'debugger'
    end
  end
  gem 'dotenv-rails'
  gem 'rubocop', require: false
end

group :test do
  gem 'capybara', '>= 2.2.0'
  gem 'capybara-webkit', '>= 1.0.0'
  gem 'cucumber-rails', require: false
  gem 'growl'
  gem 'rails-controller-testing'
  gem 'rb-fsevent'
  gem 'simplecov'
  gem 'spork'
  gem 'webrat'

  gem 'database_cleaner', '>= 1.2.0'
  gem 'guard-cucumber'
  gem 'guard-rspec'
  gem 'guard-spork'

  gem 'minitest'
end

group :production do
  gem 'libv8', '>= 3.11.8.12'
  gem 'redis-rails'
  gem 'therubyracer', '>= 0.11.4'
  # CVE-2017-1000248
  gem 'redis-store', '>= 1.4.0'
end

# gem 'capistrano', '~> 2.0'
# gem 'rvm-capistrano'

gem 'mysql2'
# for AR-4.2
gem 'pg', '~> 0.21'
# for AR-4.2
gem 'sqlite3', '~> 1.3.11'

gem 'bootsnap', require: false
gem 'coffee-rails' #, '~> 4.1.0'
gem 'haml', '>= 5.0.0'
gem 'haml-rails'
gem 'i18n'
gem 'jquery-rails'
gem 'jquery-ui-rails', '>= 5.0.0'
gem 'memoist'
gem 'puma'
gem 'sass-rails', '~> 5.0'
gem 'settingslogic'
gem 'uglifier'

# currently twitter bootstrap 3 is not supported in Sanataro
gem 'twitter-bootstrap-rails', '>= 2.2.8', '< 3'

gem 'jbuilder'
gem 'rails_emoji'
gem 'underscore-rails'

gem 'doorkeeper', '>= 0.7.1'

gem 'rails-observers'

## for database cleaner and cucumber
gem 'connection_pool'

gem 'responders'
