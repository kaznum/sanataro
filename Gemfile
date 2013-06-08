source 'http://rubygems.org'

###
### This file is for MRI
### Please see gemfiles/Gemfile.jruby for JRuby env
###

gem 'rails', github: 'rails/rails', :branch => '4-0-stable'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Use unicorn as the web server
# gem 'unicorn'

group :development, :test do
  gem "rspec-rails", ">= 2.13.1"
  gem "launchy"
  gem "fabrication"
  unless ENV['TRAVIS']
    platforms :mri_19 do
      gem 'capistrano'
      gem 'rvm-capistrano'
      gem 'debugger'
    end
  end
  gem 'dotenv-rails'
end


group :test do
  gem "simplecov"
  gem 'spork'
  platform :mri do
    gem "cucumber-rails", :require => false, :github => 'cucumber/cucumber-rails', :branch => "release-1.3.1" 
    gem "capybara-webkit", '>= 1.0.0'
    gem "growl"
    gem "rb-fsevent"
    gem "webrat"

    gem "database_cleaner", '>= 1.0.0'
    gem "guard-rspec"
    gem "guard-cucumber"
    gem "guard-spork"
  end
end

group :production do
  platform :mri do
    gem "therubyracer", '>= 0.11.4'
    gem 'libv8', '>= 3.11.8.12'
  end
end

platforms :ruby do
  gem "mysql2"
  gem 'sqlite3'
  gem 'pg'
end

group :assets do
  gem 'sass-rails', github: 'rails/sass-rails'
  gem 'coffee-rails', github: 'rails/coffee-rails'
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

# TODO
# Just temporally to support rails 4
# This is not recommended in Rails4
gem 'protected_attributes'

gem 'rails-observers'

## for database cleaner and cucumber
gem 'connection_pool'

