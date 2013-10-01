require 'spec_helper'

describe Admin::UsersController do
  def mock_user
    mock_model(User).as_null_object
  end

  describe "index" do
    after do
      ENV['ADMIN_USER'] = nil
      ENV['ADMIN_PASSWORD'] = nil
    end

    let(:user_objects) { [mock_user, mock_user, mock_user] }
    context "without authentication data in server," do
      describe "response" do
        before do
          get :index
        end

        subject {response}
        its(:status) {should == 401 }
        it {should_not render_template "index"}
      end
    end

    context "with authentication data in server's Settings," do
      context "when user/password is correct," do
        before do
          Settings.should_receive(:admin_user).and_return("admin_setting")
          Settings.should_receive(:admin_password).and_return("password_setting")
          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin_setting:password_setting")
        end

        describe "response" do
          before do
            get :index
          end
          subject {response}
          it {should be_success }
        end
      end

      context "when user/password is incorrect," do
        before do
          Settings.should_receive(:admin_user).and_return("admin_setting")
          Settings.should_receive(:admin_password).and_return("password_setting")
          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin_setting:password_settin")
        end

        describe "response" do
          before do
            get :index
          end
          subject {response}
          its(:status) {should == 401 }
        end
      end
    end

    context "with authentication setting in ENV," do
      context "when user/password is incorrect," do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin:password_env")
        end

        describe "response" do
          before { get :index }
          subject {response}
          its(:status) { should == 401 }
        end
      end

      context "when user/password is correct," do
        before do
          ENV['ADMIN_USER'] = 'admin'
          ENV['ADMIN_PASSWORD'] = 'password_env'

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin:password_env")
        end

        describe "response" do
          before do
            get :index
          end

          subject {response}
          it {should be_success}
          it {should render_template "index"}
        end
      end
    end

    context "with authentication setting in both ENV and Settings," do
      context "when EVN's user/password pair is specified," do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'
          Settings.stub(:admin_user).and_return("admin_setting")
          Settings.stub(:admin_password).and_return("password_setting")

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin_env:password_env")
        end
        describe "response" do
          before do
            get :index
          end

          subject {response}
          it {should be_success}
          it {should render_template "index"}
        end
      end

      context "when Ssettings user/password pair is specified," do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'
          Settings.stub(:admin_user).and_return("admin_setting")
          Settings.stub(:admin_password).and_return("password_setting")

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64::encode64("admin_setting:password_setting")
        end

        describe "response" do
          before { get :index }
          subject {response}
          its(:status) { should == 401 }
        end
      end
    end

    context "when authentication pass," do
      context "when user/password is correct," do
        before do
          @controller.instance_eval do |ins|
            ins.should_receive(:authenticate).and_return(true)
          end
        end

        describe "Methods calls" do
          specify do
            User.should_receive(:all).and_return(user_objects)
            get :index
            assigns(:users).should == user_objects
          end
        end

        describe "@users" do
          before do
            User.stub(:all).and_return(user_objects)
            get :index
          end

          subject { assigns(:users) }
          it { should == user_objects }
        end

        describe "response" do
          before do
            get :index
          end

          subject {response}
          it {should be_success}
          it {should render_template "index"}
        end
      end
    end
  end
end
