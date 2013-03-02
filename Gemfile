source 'http://rubygems.org'

###
### This file is for MRI
### Please see gemfiles/Gemfile.jruby for JRuby env
###

gem 'rails', '4.0.0.beta1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Use unicorn as the web server
# gem 'unicorn'


group :development, :test do
  gem "rspec-rails"
  gem "launchy"
  gem "fabrication"
  unless ENV['TRAVIS']
    platforms :mri_19 do
      gem 'capistrano'
      gem 'rvm-capistrano'
      gem 'debugger'
    end
  end
end


group :test do
  gem "simplecov"
  gem 'spork'
  platform :mri do
    gem "cucumber-rails", :require => false
    gem "capybara-webkit"
    gem "growl"
    gem "rb-fsevent"
    gem "webrat"
    gem "database_cleaner"
    gem "guard-rspec"
    gem "guard-cucumber"
    gem "guard-spork"
  end
end

group :production do
  platform :mri do
    gem "therubyracer"
    gem 'libv8', '~> 3.11.8'
  end
end

platforms :ruby do
  gem "mysql2"
  gem 'sqlite3'
  gem 'pg'
end

group :assets do
  gem 'sass-rails', '4.0.0.beta1'
  gem 'coffee-rails', '4.0.0.beta1'
  gem 'uglifier'
end

gem "i18n"
gem 'haml-rails','0.3.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'settingslogic'
gem 'coffee-filter', '0.1.3'
gem 'memoist'

gem 'twitter-bootstrap-rails'
gem 'dalli'
gem 'dalli-store-extensions', :git => "git://github.com/mqt/dalli-store-extensions.git"

gem 'rails_emoji'
gem 'jbuilder'
gem 'underscore-rails'

# Just temporally to support rails 4
gem 'doorkeeper', :git => 'git@github.com:kaznum/doorkeeper.git', :branch => 'rails4'


# Just temporally to support rails 4
# This is not recommended in Rails4
gem 'protected_attributes'

gem 'rails-observers'
