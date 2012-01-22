require 'rubygems'
require 'spork'
require 'prototype_matchers'
require 'simplecov'
SimpleCov.start "rails"

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
end

Spork.each_run do
  # This code will be run each time you run your specs.
end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require File.expand_path(File.join(Rails.root, 'lib', 'acts_as_taggable_redux', 'init'))

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  Capybara.javascript_driver = :webkit

  def login(only_add=false)
    orig_controller = @controller
    @controller = LoginController.new
    xhr :post, :do_login, :login => 'user1', :password => '123456', :autologin => true, :only_add => only_add
      @controller = orig_controller
  end
  
  def create_entry(*params)
    orig_controller = @controller
    @controller = EntriesController.new
    xhr :post, :create, *params
    @controller = orig_controller
  end

end


RSpec::Matchers.define :redirect_by_js_to do |path|
  match_unless_raises ActiveSupport::TestCase::Assertion do |_|
    assert_template "common/redirect"
    assert_equal path, assigns[:path_to_redirect_to]
  end

  failure_message_for_should do
    "expected to redirect to '#{path}', but to '#{assigns[:path_to_redirect_to]}'.\n" + rescued_exception.message
  end

  failure_message_for_should_not do |_|
    "expected not to redirect to '#{path}', but did"
  end
  
  description do
    "js redirect matcher"
  end
end

RSpec::Matchers.define :render_rjs_error do |prms|
  match_unless_raises ActiveSupport::TestCase::Assertion do |_|
    assert_template "common/error"
    prms.each do |key, value|
      if value.is_a?(Regexp)
        assert_match value, assigns(:error_rjs_params)[key]
      else
        assert_equal value, assigns(:error_rjs_params)[key]
      end
    end
  end

  failure_message_for_should do
    rescued_exception.message
  end

  failure_message_for_should_not do |_|
    "expected not to have render_rjs_error(#{prms.serialize}, but did"
  end
  
  description do
    "error.rjs matcher"
  end
end

unless defined?(CustomSharedExamplesHelper)
  module CustomSharedExamplesHelper
    shared_examples_for "Unauthenticated Access" do
      subject { response }
      it { should redirect_to login_url }
    end

    shared_examples_for "Unauthenticated Access by xhr" do
      subject { response }
      it { should redirect_by_js_to login_url }
    end
  end
end



module FakedUser
  def login_user
    @mock_user ||= mock_model(User,
                               :id => 1, 
                               :login => 'user1',
                               :password => '354274759f43fafbc9551e47bc63f077f244164e',
                               :email => 'test1@example.com',
                               :is_active => true)
  end

  class << self
    define_method :included do |mod|
      mod.instance_eval do 
        before do
          User.stub(:find_by_login_and_is_active).with("user1", true).and_return(login_user)
        end
      end
    end
  end


end
