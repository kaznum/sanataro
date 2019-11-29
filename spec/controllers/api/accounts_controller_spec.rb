# frozen_string_literal: true

require 'spec_helper'

describe Api::AccountsController, type: :controller do
  fixtures :users, :accounts

  describe '#index' do
    context 'before login,' do
      before do
        get :index, format: :json
      end

      it_should_behave_like 'Unauthenticated Access in API'
    end

    context 'access successfully with basic auth,' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('user1', '123456')
        get :index, format: :json
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_successful }
        it { is_expected.to render_template :index }
      end
    end

    context 'with wrong password at basic auth,' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('user1', '1234')
        get :index, format: :json
      end

      it_should_behave_like 'Unauthenticated Access in API'
    end

    context 'with wrong login at basic auth,' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('user999', '123456')
        get :index, format: :json
      end

      it_should_behave_like 'Unauthenticated Access in API'
    end

    context 'with OAuth,' do
      context 'when resource_owner_id is correct,' do
        before do
          token = double(Doorkeeper::AccessToken, acceptable?: true, resource_owner_id: users(:user1).id)
          @controller.define_singleton_method(:doorkeeper_token) do
            token
          end
          get :index, format: :json
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_successful }
          it { is_expected.to render_template :index }
        end
      end

      context 'when resource_owner_id is wrong,' do
        before do
          token = double(Doorkeeper::AccessToken, acceptable?: true, resource_owner_id: 999_999)
          @controller.define_singleton_method(:doorkeeper_token) do
            token
          end
          get :index, format: :json
        end

        it_should_behave_like 'Unauthenticated Access in API'
      end
    end

    context 'after login,' do
      before do
        dummy_login
        get :index, format: :json
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_successful }
        it { is_expected.to render_template :index }
      end
    end
  end
end
