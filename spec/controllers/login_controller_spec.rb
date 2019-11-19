# frozen_string_literal: true

require 'spec_helper'

describe LoginController, type: :controller do
  fixtures :users, :autologin_keys

  describe '#login' do
    shared_examples_for 'render login' do
      subject { response }
      it { is_expected.to be_success }
      it { is_expected.to render_template 'login' }
    end

    context 'without autologin cookie,' do
      before do
        get :login
      end

      describe 'response' do
        subject { response }
        it_should_behave_like 'render login'
      end
    end

    context 'with session[:user_id],' do
      before do
        session[:user_id] = users(:user1).id
        get :login
      end

      subject { response }
      it { is_expected.to redirect_to current_entries_url }
    end

    context 'with session[:disable_autologin],' do
      before do
        session[:disable_autologin] = true
        get :login
      end

      describe 'session' do
        subject { session }

        describe '[:disable_autologin]' do
          subject { super()[:disable_autologin] }
          it { is_expected.to be_falsey }
        end
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'login' }
      end
    end

    context 'with user cookie, ' do
      before do
        @request.cookies['user'] = 'user1'
      end

      context 'with autologin cookie,' do
        before do
          @request.cookies['autologin'] = '1234567'
        end

        describe 'response' do
          before do
            get :login
          end
          subject { response }
          it { is_expected.to redirect_to current_entries_url }
        end

        context 'with only_add cookie,' do
          before do
            @request.cookies['only_add'] = '1'
            get :login
          end

          describe 'response' do
            subject { response }
            it { is_expected.to redirect_to simple_input_url }
          end
        end
      end

      context 'without autologin cookie,' do
        describe 'response' do
          before do
            get :login
          end
          it_should_behave_like 'render login'
        end

        context 'with only_add cookie,' do
          before do
            @request.cookies['only_add'] = '1'
            get :login
          end
          it_should_behave_like 'render login'
        end
      end
    end
  end

  describe '#do_login' do
    context 'with invalid password,' do
      before do
        xhr :post, :do_login, login: 'user1', password: 'user1', autologin: nil, only_add: nil
      end

      describe 'cookies' do
        subject { cookies }

        describe "['user']" do
          subject { super()['user'] }
          it { is_expected.to be_nil }
        end

        describe "['autologin']" do
          subject { super()['autologin'] }
          it { is_expected.to be_nil }
        end

        describe "['only_add']" do
          subject { super()['only_add'] }
          it { is_expected.to be_nil }
        end
      end

      describe 'response' do
        subject { response }
        it { is_expected.to render_js_error id: 'warning', default_message: I18n.t('error.user_or_password_is_invalid') }
      end
    end

    context 'without autologin and only_add,' do
      before do
        xhr :post, :do_login, login: 'user1', password: '123456', autologin: nil, only_add: nil
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to current_entries_url }
      end

      describe 'session' do
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to eq(users(:user1).id) }
        end
      end

      describe 'cookies' do
        subject { cookies }

        describe "['user']" do
          subject { super()['user'] }
          it { is_expected.to be_nil }
        end

        describe "['autologin']" do
          subject { super()['autologin'] }
          it { is_expected.to be_nil }
        end

        describe "['only_add']" do
          subject { super()['only_add'] }
          it { is_expected.to be_nil }
        end
      end
    end

    context 'when AutologinKey.cleanup is called,' do
      it 'should send AutologinKey.cleanup,' do
        expect(AutologinKey).to receive(:cleanup)
        xhr :post, :do_login, login: users(:user1).login, password: '123456', autologin: '1', only_add: '1'
      end
    end

    context 'with autologin = 1 and only_add = nil in params,' do
      before do
        xhr :post, :do_login, login: 'user1', password: '123456', autologin: '1', only_add: nil
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to current_entries_url }
      end

      describe 'cookies' do
        subject { cookies }

        describe "['user']" do
          subject { super()['user'] }
          it { is_expected.to eq(users(:user1).login) }
        end

        describe "['autologin']" do
          subject { super()['autologin'] }
          it { is_expected.not_to be_nil }
        end

        describe "['only_add']" do
          subject { super()['only_add'] }
          it { is_expected.to be_nil }
        end
      end

      describe 'session' do
        subject { session }

        describe "['user_id']" do
          subject { super()['user_id'] }
          it { is_expected.to eq(users(:user1).id) }
        end
      end

      describe 'AutologinKey.count' do
        subject { AutologinKey.where(user_id: users(:user1).id).where('created_at > ?', DateTime.now - 30).count }
        it { is_expected.to be > 0 }
      end
    end

    context 'with autologin = 1 and only_add = 1 in params,' do
      before do
        xhr :post, :do_login, login: 'user1', password: '123456', autologin: '1', only_add: '1'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to simple_input_url }
      end

      describe 'cookies' do
        subject  { cookies }

        describe "['user']" do
          subject { super()['user'] }
          it { is_expected.to eq(users(:user1).login) }
        end

        describe "['autologin']" do
          subject { super()['autologin'] }
          it { is_expected.not_to be_nil }
        end

        describe "['only_add']" do
          subject { super()['only_add'] }
          it { is_expected.to eq('1') }
        end
      end

      describe 'session' do
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to eq(users(:user1).id) }
        end
      end

      describe 'AutologinKey.count' do
        subject { AutologinKey.where(user_id: users(:user1).id).where('created_at > ?', DateTime.now - 30).count }
        it { is_expected.to be > 0 }
      end
    end
  end

  describe '#do_logout' do
    context 'before login,' do
      before do
        @previous_count_of_autologin_keys = AutologinKey.count
        get :do_logout
      end

      describe 'count of autologin keys' do
        subject { AutologinKey.count }
        it { is_expected.to eq(@previous_count_of_autologin_keys) }
      end

      describe 'session' do
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end

    context 'after login,' do
      context 'without autologin in cookies,' do
        before do
          dummy_login
          get :do_logout
        end

        describe 'response' do
          subject { response }
          it { is_expected.to redirect_to login_url }
        end

        describe 'session' do
          subject { session }

          describe '[:user_id]' do
            subject { super()[:user_id] }
            it { is_expected.to be_nil }
          end

          describe '[:disable_autologin]' do
            subject { super()[:disable_autologin] }
            it { is_expected.to be_truthy }
          end
        end
      end

      context 'with autologin in cookies,' do
        before do
          dummy_login
          login_user_id = users(:user1).id
          mock_ak = mock_model(AutologinKey, user_id: login_user_id)
          expect(mock_ak).to receive(:destroy)
          expect(AutologinKey).to receive(:matched_key).with(login_user_id, '12345abc').and_return(mock_ak)
          @request.cookies['autologin'] = '12345abc'
          get :do_logout
        end

        describe 'response' do
          subject { response }
          it { is_expected.to redirect_to login_url }
        end

        describe 'session' do
          subject { session }

          describe '[:disable_autologin]' do
            subject { super()[:disable_autologin] }
            it { is_expected.to be_truthy }
          end

          describe '[:user_id]' do
            subject { super()[:user_id] }
            it { is_expected.to be_nil }
          end
        end
      end
    end
  end

  describe '#create_user' do
    before do
      get :create_user
    end

    subject { response }
    it { is_expected.to be_success }
    it { is_expected.to render_template 'create_user' }
  end

  describe '#do_create_user' do
    context 'when params are all valid,' do
      before do
        xhr :post, :do_create_user, login: 'hogehoge', password_plain: 'hagehage', password_confirmation: 'hagehage', email: 'email@example.com'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to render_template 'do_create_user' }
        it { is_expected.to be_success }
      end

      describe 'created user' do
        subject { User.order('id desc').first }

        describe '#confirmation' do
          subject { super().confirmation }
          it { is_expected.not_to be_nil }
        end

        describe '#confirmation' do
          subject { super().confirmation }

          it 'has 15 characters' do
            expect(subject.size).to eq(15)
          end
        end
        it { is_expected.not_to be_active }
      end
    end

    context 'when validation errors happens,' do
      before do
        mock_user = mock_model(User)
        expect(User).to receive(:new).once.and_return(mock_user)
        expect(mock_user).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(mock_user))
        expect(mock_user).to receive(:errors).and_return([])
        xhr :post, :do_create_user, login: 'hogehoge2', password_plain: 'hagehage', password_confirmation: 'hhhhhhh', email: 'email@example.com'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to render_js_error id: 'warning', default_message: '' }
      end
    end
  end

  describe '#confirmation' do
    context 'when params are correct,' do
      before do
        mock_user = mock_model(User)
        expect(User).to receive(:find_by_login_and_confirmation).with('test200', '123456789012345').and_return(mock_user)
        expect(mock_user).to receive(:store_sample)

        expect(mock_user).to receive(:update_attributes!).with(active: true)
        expect(mock_user).to receive(:deliver_signup_complete)
        user = User.new(password: '1234567', password_confirmation: '1234567', confirmation: '123456789012345', email: 'test@example.com', active: false)
        user.login = 'test200'
        user.save!
        get :confirmation, login: 'test200', sid: '123456789012345'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'confirmation' }
      end
    end

    context 'when params[:sid] are correct,' do
      before do
        user = User.new(password: '1234567', password_confirmation: '1234567', confirmation: '123456789012345', email: 'test@example.com', active: false)
        user.login = 'test200'
        user.save!
        mock_user = mock_model(User).as_null_object
        expect(User).to receive(:find_by_login_and_confirmation).with('test200', '1234567890').and_return(nil)
        expect(mock_user).not_to receive(:update_attributes!).with(active: true)
        mock_mailer = double
        expect(mock_mailer).not_to receive(:deliver)
        expect(Mailer).not_to receive(:signup_complete).with(an_instance_of(User))
        get :confirmation, login: 'test200', sid: '1234567890'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'confirmation_error' }
      end
    end
  end
end
