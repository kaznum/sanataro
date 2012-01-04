# -*- coding: utf-8 -*-
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'rubygems'
require 'spork'

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





#class Test::Unit::TestCase
class ActiveSupport::TestCase

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
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

  def assert_select_rjs_warning(msg)
    assert_rjs :replace_html, "warning", msg
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
  end

  #### replace for arts
  def assert_rjs(*args, &block)
    args[0] = :redirect if args[0].to_sym == :redirect_to
    #    if args[0].to_sym == :visual_effect
    #      print ("v")
    #    else
    assert_select_rjs(*args, &block)
    #    end
  end

  def assert_no_rjs(*args, &block)
    rjs_type = args[0].to_sym
    if rjs_type == :redirect_to
      rjs_type = args[0] = :redirect 
    end
    
    self.class_eval do
      alias_method :orig_flunk, :flunk
      define_method :flunk do |*a|
        nil
      end
    end

    matches = assert_select_rjs(*args, &block)
    
    self.class_eval do
      alias_method :flunk, :orig_flunk
    end
    
    if matches
      orig_flunk("#{rjs_type} should not exist but exists")
    else
      args
    end
  end


  # RAILS2.x => 3への移行のため、一時的に停止
  unless method_defined? :orig_assert_valid_markup
    alias_method :orig_assert_valid_markup, :assert_valid_markup
    def assert_valid_markup(*args, &block)
      print("m")
    end
  end
end

class ActionController::TestCase
  unless method_defined?(:orig_assert_select_rjs)
    
    alias_method :orig_assert_select_rjs, :assert_select_rjs
    
    def assert_select_rjs(*args, &block)
      rjs_type = args[0].to_sym

      # see ActionDispatch::Assertions::SelectorAssertions
      case rjs_type
      when :redirect
        args[1] = Regexp.escape(args[1]) if args[1].is_a?(String)
      when :replace, :replace_html
        args[1] = args[1].to_s if args[1].is_a?(Symbol)
        args[2] = Regexp.escape(args[2]) if args[2].is_a?(String)
      when :insert, :insert_html
        args[2] = args[2].to_s if args[2].is_a?(Symbol)
        args[3] = Regexp.escape(args[3]) if args[3].is_a?(String)
      when :visual_effect
        args.shift
      end
      if rjs_type == :visual_effect
        assert_rjs_visual_effect(*args, &block)
      else
        orig_assert_select_rjs(*args, &block)
      end
      
    end
  end

  #
  #sample new Effect.SlideUp(\"tag_status_body\",{duration:0.2})
  #
  def assert_rjs_visual_effect(effect, tag_id, options = {}, &block)
    if !@response
      flunk "responseまたはbodyがありません。"
    else
      matches = @response.body.match(/new Effect\.#{effect.to_s.camelize}\("#{tag_id.to_s}"(,\{.*\})\)/).to_a
      if matches.empty?
        flunk "visual_effect, :#{effect}, :#{tag_id} は存在しません"
      else
        matched_option = matches[1]
        if matched_option
          options.keys.each do |key|
            unless matched_option =~ /#{key}:#{options[key]}/
              flunk "visual_effect, :#{effect}, :#{tag_id}はありますが、 オプション #{key}:#{options[key]} は存在しません"
            end
          end
        end
        matches
      end
    end
  end
end

### RAILS2.xからの移行に伴う変更点の判定に使用エラーがなくなった時点で削除する
module ActionView
  module Helpers
    module FormTagHelper
      unless method_defined? :orig_form_tag
        alias_method :orig_form_tag, :form_tag
        def form_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)
          [:url, :html].each do |key|
            if (url_for_options.is_a?(Hash) && (url_for_options.key?(key))) ||
                ( options.is_a?(Hash) && options.key?(:key))
              raise "form_tagに :#{key.to_s} オプションが指定されています"
            end
          end
          orig_form_tag(url_for_options, options, *parameters_for_url, &block)
        end
      end
    end
    module UrlHelper
      unless method_defined? :orig_link_to
        alias_method :orig_link_to, :link_to
        def link_to(*args, &block)
          args.each do |arg|
            if arg.is_a?(Hash) && arg.key?(:url)
              raise "link_toに :url オプションが指定されています"
            end
          end
          orig_link_to(*args, &block)
        end
      end
    end
  end
end
