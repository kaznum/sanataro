source 'http://rubygems.org'

###
### This file is for MRI
### Please see gemfiles/Gemfile.jruby for JRuby env
###

gem 'rails', '>= 4.0.0'

# Use unicorn as the web server
# gem 'unicorn'

group :development, :test do
  gem "rspec-rails", ">= 2.13.1"
  gem "launchy"
  gem "fabrication"
  unless ENV['TRAVIS']
    gem 'debugger'
  end
  gem 'dotenv-rails'
end


group :test do
  gem "simplecov"
  gem 'spork'
  gem "cucumber-rails"
  gem "capybara-webkit", '>= 1.0.0'
  gem "growl"
  gem "rb-fsevent"
  gem "webrat"

  # TODO
  # PostgreSQLAdapter is being used with sqlite3
  # https://github.com/bmabey/database_cleaner/issues/224
  gem "database_cleaner", '>= 1.0.0', '< 1.1.0'
  gem "guard-rspec"
  gem "guard-cucumber"
  gem "guard-spork"
end

group :production do
  gem "therubyracer", '>= 0.11.4'
  gem 'libv8', '>= 3.11.8.12'
end

platforms :ruby do
  gem "mysql2"
  gem 'sqlite3'
  gem 'pg'
end

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

gem "i18n"

gem "haml", '>= 4.0.2'

gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'settingslogic'
gem 'memoist'

gem 'twitter-bootstrap-rails'
gem 'dalli'
gem 'dalli-store-extensions', :github => "mqt/dalli-store-extensions"

gem 'rails_emoji'
gem 'jbuilder'
gem 'underscore-rails'

# TODO
# Just temporally to support rails 4
gem 'doorkeeper', :git => 'git://github.com/kaznum/doorkeeper.git', :branch => 'remove_has_many_warning'

gem 'rails-observers'

## for database cleaner and cucumber
gem 'connection_pool'

