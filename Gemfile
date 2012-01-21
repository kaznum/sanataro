source 'http://rubygems.org'

gem 'rails', '3.2.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

#gem 'sqlite3-ruby', :require => 'sqlite3'
# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

gem "therubyracer"

group :development, :test do
  gem "gettext"
  gem "rails-erd"
  gem "libnotify" if RUBY_PLATFORM.downcase =~ /linux/
  gem "rb-inotify" if RUBY_PLATFORM.downcase =~ /linux/
  if RUBY_VERSION >= "1.9"
   gem 'ruby-debug19'
  end
  gem "capybara-webkit"
  gem "cucumber-rails"
  gem "launchy"
  gem "fabrication"
end

gem 'haml-rails'

group :watchr do
#  gem "watchr"
#  gem "rev" if RUBY_PLATFORM.downcase =~ /linux/
end

group :test do
  gem "database_cleaner"
  gem "guard-rspec"
  gem "guard-cucumber"
  gem "guard-spork"
  gem "growl" if RUBY_PLATFORM.downcase =~ /darwin/
  gem "rspec"
  gem "rspec-rails"
  gem "rb-fsevent" if RUBY_PLATFORM.downcase =~ /darwin/
  gem "assert_valid_markup"
  if RUBY_VERSION >= "1.9"
    gem 'spork', '~> 0.9.0.rc'
  else
    gem 'spork', '~> 0.8'
  end
  gem "webrat"
  gem "simplecov" if RUBY_VERSION >= "1.9"
end

gem "fast_gettext"
gem "gettext_i18n_rails"
if defined?(JRUBY_VERSION)
  gem "jruby-openssl"
  gem "activerecord-jdbcmysql-adapter"
else
  gem "mysql2", '~> 0.3'
end
gem 'prototype-rails'

group :assets do
# sass-rails and coffee-rails don't support rails 3.2 now, so
# they are commented out temporarily.
#  gem 'sass-rails'
#  gem 'coffee-rails'
  gem 'sass'
  gem 'coffee-script'
  gem 'uglifier'
end

