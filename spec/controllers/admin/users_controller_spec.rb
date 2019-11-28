# frozen_string_literal: true

require 'spec_helper'

describe Admin::UsersController, type: :controller do
  def mock_user
    mock_model(User).as_null_object
  end

  describe 'index' do
    after do
      ENV['ADMIN_USER'] = nil
      ENV['ADMIN_PASSWORD'] = nil
    end

    let(:user_objects) { [mock_user, mock_user, mock_user] }
    context 'without authentication data in server,' do
      describe 'response' do
        before do
          get :index
        end

        subject { response }

        describe '#status' do
          subject { super().status }
          it { is_expected.to eq(401) }
        end
        it { is_expected.not_to render_template 'index' }
      end
    end

    context "with authentication data in server's Settings," do
      context 'when user/password is correct,' do
        before do
          expect(GlobalSettings).to receive(:admin_user).and_return('admin_setting')
          expect(GlobalSettings).to receive(:admin_password).and_return('password_setting')
          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin_setting:password_setting')
        end

        describe 'response' do
          before do
            get :index
          end
          subject { response }
          it { is_expected.to be_successful }
        end
      end

      context 'when user/password is incorrect,' do
        before do
          expect(GlobalSettings).to receive(:admin_user).and_return('admin_setting')
          expect(GlobalSettings).to receive(:admin_password).and_return('password_setting')
          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin_setting:password_settin')
        end

        describe 'response' do
          before do
            get :index
          end
          subject { response }

          describe '#status' do
            subject { super().status }
            it { is_expected.to eq(401) }
          end
        end
      end
    end

    context 'with authentication setting in ENV,' do
      context 'when user/password is incorrect,' do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin:password_env')
        end

        describe 'response' do
          before { get :index }
          subject { response }

          describe '#status' do
            subject { super().status }
            it { is_expected.to eq(401) }
          end
        end
      end

      context 'when user/password is correct,' do
        before do
          ENV['ADMIN_USER'] = 'admin'
          ENV['ADMIN_PASSWORD'] = 'password_env'

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin:password_env')
        end

        describe 'response' do
          before do
            get :index
          end

          subject { response }
          it { is_expected.to be_successful }
          it { is_expected.to render_template 'index' }
        end
      end
    end

    context 'with authentication setting in both ENV and Settings,' do
      context "when EVN's user/password pair is specified," do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'
          allow(GlobalSettings).to receive(:admin_user).and_return('admin_setting')
          allow(GlobalSettings).to receive(:admin_password).and_return('password_setting')

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin_env:password_env')
        end
        describe 'response' do
          before do
            get :index
          end

          subject { response }
          it { is_expected.to be_successful }
          it { is_expected.to render_template 'index' }
        end
      end

      context 'when Ssettings user/password pair is specified,' do
        before do
          ENV['ADMIN_USER'] = 'admin_env'
          ENV['ADMIN_PASSWORD'] = 'password_env'
          allow(GlobalSettings).to receive(:admin_user).and_return('admin_setting')
          allow(GlobalSettings).to receive(:admin_password).and_return('password_setting')

          request.env['HTTP_AUTHORIZATION'] =
            'Basic ' + Base64.encode64('admin_setting:password_setting')
        end

        describe 'response' do
          before { get :index }
          subject { response }

          describe '#status' do
            subject { super().status }
            it { is_expected.to eq(401) }
          end
        end
      end
    end

    context 'when authentication pass,' do
      context 'when user/password is correct,' do
        before do
          expect(@controller).to receive(:authenticate).and_return(true)
        end

        describe 'Methods calls' do
          specify do
            expect(User).to receive(:all).and_return(user_objects)
            get :index
            expect(assigns(:users)).to eq(user_objects)
          end
        end

        describe '@users' do
          before do
            allow(User).to receive(:all).and_return(user_objects)
            get :index
          end

          subject { assigns(:users) }
          it { is_expected.to eq(user_objects) }
        end

        describe 'response' do
          before do
            get :index
          end

          subject { response }
          it { is_expected.to be_successful }
          it { is_expected.to render_template 'index' }
        end
      end
    end
  end
end
