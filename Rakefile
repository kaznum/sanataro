# frozen_string_literal: true
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# see https://github.com/jruby/jruby/wiki/FAQs
# To escape undefined method 'create_database' for class '#Class:01x1e30857'"
ENV['SKIP_AR_JDBC_RAKE_REDEFINES'] = '1'

require File.expand_path('config/application', __dir__)

Sanataro::Application.load_tasks

task travis: defined?(JRUBY_VERSION) ? ['spec:routing', 'spec:lib', 'spec:helpers', 'spec:views', 'spec:models', 'spec:controllers'] : ['assets:precompile', :spec, :cucumber]
