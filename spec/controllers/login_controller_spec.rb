# -*- coding: utf-8 -*-
require 'spec_helper'

describe LoginController do
  fixtures :users, :autologin_keys

  describe "index" do
    context "belore login" do
      before do
        get :index
      end
      it_should_behave_like "Unauthenticated Access"
    end

    context "after login," do
      before do
        login
        get :index
      end

      subject {response}
      it {should redirect_to login_url }
    end
  end
  
  describe "login" do
    shared_examples_for "render login" do
      subject {response}
      it {should be_success }
      it {should render_template "login" }
    end
      
    context "without autologin cookie," do
      before do
        get :login
      end

      describe "response" do
        subject {response}
        it_should_behave_like "render login"
      end
    end

    context "with session[:disable_autologin]," do
      before do
        session[:disable_autologin] = true
        get :login
      end

      describe "session" do
        subject {session}
        its([:disable_autologin]) {should be_false}
      end

      describe "response" do
        subject {response}
        it {should be_success}
        it {should render_template 'login'}
      end
    end
    
    context "with user cookie, " do
      before do
        @request.cookies['user'] = 'user1'
      end

      context "with autologin cookie," do
        before do
          @request.cookies['autologin'] = '1234567'
        end
      
        describe "response" do
          before do
            get :login
          end
          subject {response}
          it {should redirect_to current_entries_url}
        end

        context "with only_add cookie," do
          before do
            @request.cookies['only_add'] = '1'
            get :login
          end

          describe "response" do
            subject {response}
            it { should redirect_to simple_input_path }
          end
        end
      end

      context "without autologin cookie," do
        describe "response" do
          before do
            get :login
          end
          it_should_behave_like "render login"
        end

        context "with only_add cookie," do
          before do
            @request.cookies['only_add'] = '1'
            get :login
          end
          it_should_behave_like "render login"
        end
      end
    end
  end
  
  describe "do_login" do
    context "with invalid password," do
      before do
        xhr :post, :do_login, :login=>'user1', :password=>'user1', :autologin=>nil, :only_add=>nil
      end

      describe "cookies" do
        subject {cookies}
        its(['user']) {should be_nil}
        its(['autologin']) {should be_nil}
        its(['only_add']) {should be_nil}
      end

      describe "response" do
        subject {response}
        it {should render_js_error :id => "warning", :default_message => I18n.t("error.user_or_password_is_invalid") }
      end
    end

    context "without autologin and only_add" do
      before do
        xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>nil, :only_add=>nil
      end

      describe "response" do
        subject {response}
        it {should redirect_by_js_to current_entries_url}
      end

      describe "session" do
        subject {session}
        its([:user_id]) {should be == users(:user1).id}
      end

      describe "cookies" do
        subject {cookies}
        its(['user']) {should be_nil}
        its(['autologin']) {should be_nil}
        its(['only_add']) {should be_nil}
      end
    end
    
    describe "AutologinKey.cleanup is called," do 
      it "should send AutologinKey.cleanup," do
        AutologinKey.should_receive(:cleanup).with(users(:user1).id)
        xhr :post, :do_login, :login => users(:user1).login, :password=>'123456', :autologin => "1", :only_add=>'1'
      end
    end
    
    context "with autologin = 1 and only_add = nil in params," do
      before do
        xhr :post, :do_login, :login => 'user1', :password => '123456', :autologin => '1', :only_add => nil
      end

      describe "response" do
        subject {response}
        it {should redirect_by_js_to current_entries_url}
      end
      
      describe "cookies" do
        subject {cookies}
        its(['user']) {should be == users(:user1).login}
        its(['autologin']) {should_not be_nil}
        its(['only_add']) {should be_nil}
      end

      describe "session" do
        subject {session}
        its(['user_id']) { should be == users(:user1).id}
        
      end

      describe "AutologinKey.count" do
        subject { AutologinKey.where(:user_id => users(:user1).id).where("created_at > ?", DateTime.now - 30).count }
        it { should be > 0 }
      end
    end

    context "with autologin = 1 and only_add = 1 in params" do
      before do
        xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>'1', :only_add=>'1'
      end

      describe "response" do
        subject {response}
        it {should redirect_by_js_to simple_input_path }
      end
      
      describe "cookies" do
        subject {cookies}
        its(['user']) { should be == users(:user1).login }
        its(['autologin']) { should_not be_nil }
        its(['only_add']) { should be == '1'}
      end

      describe "session" do
        subject {session}
        its([:user_id]) { should be == users(:user1).id }
      end

      describe "AutologinKey.count" do
        subject { AutologinKey.where(:user_id => users(:user1).id).where("created_at > ?", DateTime.now - 30).count }
        it { should be > 0 }
      end
      
    end

  end

  describe "do_logout" do
    context "before login" do
      before do
        @previous_count_of_autologin_keys = AutologinKey.count
        get :do_logout
      end

      describe "count of autologin keys" do
        subject {AutologinKey.count}
        it {should be == @previous_count_of_autologin_keys}
      end

      describe "session" do
        subject {session}
        its([:user_id]) { should be_nil }
      end
    end

    context "after login" do
      context "without autologin in cookies" do 
        before do
          login
          get :do_logout
        end

        describe "response" do
          subject {response}
          it {should redirect_to login_url }
        end

        describe "session" do
          subject {session}
          its([:user_id]) { should be_nil }
          its([:disable_autologin]) { should be_true }
        end
      end

      context "with autologin in cookies" do 
        before do
          login
          login_user_id = users(:user1).id
          mock_ak = mock_model(AutologinKey, :user_id => login_user_id)
          mock_ak.should_receive(:destroy)
          AutologinKey.should_receive(:matched_key).with(login_user_id, "12345abc").and_return(mock_ak)
          @request.cookies['autologin'] = '12345abc'
          get :do_logout
        end
        
        describe "response" do
          subject {response}
          it {should redirect_to login_url }
        end

        describe "session" do
          subject {session}
          its([:disable_autologin]) { should be_true }
          its([:user_id]) { should be_nil }
        end
      end
    end
  end

  describe "create_user" do
    before do
      get :create_user
    end

    subject {response}
    it { should be_success }
    it { should render_template "create_user" }
  end


  describe "do_create_user" do
    context "params are all valid," do
      before do
        xhr :post, :do_create_user, :login=>'hogehoge', :password_plain=>'hagehage', :password_confirmation=>'hagehage', :email => 'email@example.com'
      end

      describe "response" do 
        subject {response}
        it {should render_template "do_create_user"}
        it {should be_success}
      end

      describe "created user" do
        subject {User.order("id desc").first}
        its(:confirmation) {should_not be_nil}
        its(:confirmation) {should have(15).characters}
        it { should_not be_active}
      end
    end

    context "when validation errors happens," do
      before do
        mock_user = mock_model(User)
        User.should_receive(:new).once.and_return(mock_user)
        mock_user.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(mock_user))
        mock_user.should_receive(:errors).and_return([])
        xhr :post, :do_create_user, :login=>'hogehoge2', :password_plain=>'hagehage', :password_confirmation=>'hhhhhhh', :email => 'email@example.com'
      end

      describe "response" do
        subject {response}
        it {should render_js_error :id => "warning", :default_message => '' }
      end
    end
  end

  describe "confirmation" do
    context "when params are correct," do 
      before do
        mock_user = mock_model(User)
        User.should_receive(:find_by_login_and_confirmation).with('test200', '123456789012345').and_return(mock_user)
        mock_user.should_receive(:accounts).exactly(13).times.and_return(@mock_accounts = mock([Account]))
        mock_user.should_receive(:credit_relations).once.and_return(@mock_crs = mock([CreditRelation]))
        mock_user.should_receive(:items).twice.and_return(@mock_items = mock([Item]))
        @mock_accounts.should_receive(:create).exactly(13).times.and_return(@account = mock(Account))
        @account.should_receive(:id).exactly(6).times.and_return(100)
        @mock_crs.should_receive(:create).once.times
        @mock_items.should_receive(:create).twice
        
        mock_user.should_receive(:update_attributes!).with(:active => true)
        mock_user.should_receive(:deliver_signup_complete)
        user = User.new(:password => '1234567', :password_confirmation => '1234567', :confirmation => '123456789012345', :email => 'test@example.com', :active => false)
        user.login = 'test200'
        user.save!
        get :confirmation, :login => 'test200', :sid => '123456789012345'
      end

      describe "response" do
        subject {response}
        it {should be_success}
        it {should render_template "confirmation"}
      end
    end

    context "when params[:sid] are correct," do 
      before do
        user = User.new(:password => '1234567', :password_confirmation => '1234567', :confirmation => '123456789012345', :email => 'test@example.com', :active => false)
        user.login = 'test200'
        user.save!
        mock_user = mock_model(User).as_null_object
        User.should_receive(:find_by_login_and_confirmation).with('test200', '1234567890').and_return(nil)
        mock_user.should_not_receive(:update_attributes!).with(:active => true)
        mock_mailer = double
        mock_mailer.should_not_receive(:deliver)
        Mailer.should_not_receive(:signup_complete).with(an_instance_of(User)).and_return(mock_mailer)
        get :confirmation, :login => 'test200', :sid => '1234567890'
      end

      describe "response" do
        subject {response}
        it {should be_success}
        it {should render_template "confirmation_error"}
      end
    end
  end
end
