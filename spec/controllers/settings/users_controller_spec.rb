# frozen_string_literal: true

require 'spec_helper'

describe Settings::UsersController, type: :controller do
  fixtures :users
  describe '#show' do
    context 'before login,' do
      before do
        get :show
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_to login_url }
      end
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when the method is valid,' do
        before do
          get :show
        end

        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'show' }
      end
    end
  end

  describe '#update' do
    context 'before login,' do
      before do
        xhr :put, :update, password_plain: '1234567', password_confirmation: '1234567', email: 'hogehoge@example.com'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to login_url }
      end
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when the method is correct,' do
        context 'when all params are correct,' do
          before do
            user1 = users(:user1)
            expect(User).to receive(:find).with(user1.id).at_least(1).and_return(user1)
            expect(user1).to receive(:email=).with('hogehoge@example.com')
            expect(user1).to receive(:password_plain=).with('1234567')
            expect(user1).to receive(:password_confirmation=).with('1234567')
            expect(user1).to receive(:save!)
            @user1 = user1

            xhr :put, :update, password_plain: '1234567', password_confirmation: '1234567', email: 'hogehoge@example.com'
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_template 'update' }
          end

          describe 'session' do
            subject { session }

            describe '[:user_id]' do
              subject { super()[:user_id] }
              it { is_expected.to eq(users(:user1).id) }
            end
          end

          describe '@user_to_change' do
            subject { assigns(:user_to_change) }

            describe '#object_id' do
              subject { super().object_id }
              it { is_expected.to eq(@user1.object_id) }
            end
          end
        end
        context 'when validation error happens.' do
          before do
            user1 = users(:user1)
            expect(User).to receive(:find).with(user1.id).at_least(1).and_return(user1)
            expect(user1).to receive(:email=).with('hogehoge@example.com')
            expect(user1).to receive(:password_plain=).with('123456789')
            expect(user1).to receive(:password_confirmation=).with('1234567')
            expect(user1).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(user1))
            xhr :put, :update, password_plain: '123456789', password_confirmation: '1234567', email: 'hogehoge@example.com'
            @user1 = user1
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id: 'warning', errors: @user1.errors, default_message: I18n.t('error.input_is_invalid') }
          end
        end
      end
    end
  end
end
