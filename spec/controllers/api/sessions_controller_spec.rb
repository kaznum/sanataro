# -*- coding: utf-8 -*-

require 'spec_helper'

describe Api::SessionsController, type: :controller do
  fixtures :users

  describe '#create' do
    context 'when params[:session] does not mismatch,' do
      before do
        @action = -> { post :create, login: users(:user1).login, password: '123456' }
      end

      describe 'response' do
        before { @action.call }
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(401) }
        end
      end

      describe 'session' do
        before { @action.call }
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end

    context "when user doesn't exist," do
      before do
        @action = -> { post :create, session: { login: 'not_exist', password: 'not_exist_pass' } }
      end

      describe 'response' do
        before { @action.call }
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(401) }
        end
      end

      describe 'session' do
        before { @action.call }
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end

    context 'when user exists but password mismatches,' do
      before do
        @action = -> { post :create, session: { login: users(:user1).login, password: 'not_match_pass' } }
      end

      describe 'response' do
        before { @action.call }
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(401) }
        end
      end

      describe 'session' do
        before { @action.call }
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end

    context 'when user exists and password matches,' do
      before do
        @action = -> { post :create, session: { login: users(:user1).login, password: '123456' }, format: :json }
      end

      describe 'response' do
        before { @action.call }
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(200) }
        end

        describe '#body' do
          subject { super().body }
          it { is_expected.to match /{"authenticity_token":".+"}/ }
        end
      end

      describe 'session' do
        before { @action.call }
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to eq(users(:user1).id) }
        end
      end
    end
  end

  describe '#destroy' do

    describe 'when user has not been logged in,' do
      before { delete :destroy }
      describe 'response' do
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(200) }
        end
      end

      describe 'session' do
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end

    describe 'when user has been logged in,' do
      before do
        session[:user_id] = users(:user1).id
        delete :destroy
      end

      describe 'response' do
        subject { response }

        describe '#response_code' do
          subject { super().response_code }
          it { is_expected.to eq(200) }
        end
      end

      describe 'session' do
        subject { session }

        describe '[:user_id]' do
          subject { super()[:user_id] }
          it { is_expected.to be_nil }
        end
      end
    end
  end
end
