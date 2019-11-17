# -*- coding: utf-8 -*-
require 'spec_helper'

describe Settings::CreditRelationsController, type: :controller do
  fixtures :users, :credit_relations

  describe '#index' do
    context 'before login,' do
      before do
        expect(User).to receive(:find).with(nil).and_raise(ActiveRecord::RecordNotFound.new)
        get :index
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

      context 'when access successfully, ' do
        before do
          mock_user = users(:user1)
          mock_credit_relations = double
          expect(mock_user).to receive(:credit_relations).and_return(mock_credit_relations)
          expect(mock_credit_relations).to receive(:all).and_return([])
          expect(User).to receive(:find).with(mock_user.id).and_return(mock_user)
          get :index
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index' }
        end
      end
    end
  end

  describe '#show' do
    context 'before login,' do
      before do
        xhr :get, :show, id: credit_relations(:cr1).id
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when successful access,' do
        before do
          @mock_user = users(:user1)
          expect(User).to receive(:find).with(@mock_user.id).and_return(@mock_user)
          @mock_credit_relations = double
          @mock_credit_relation = mock_model(CreditRelation)
          expect(@mock_user).to receive(:credit_relations).and_return(@mock_credit_relations)
          expect(@mock_credit_relations).to receive(:find).with('11111').and_return(@mock_credit_relation)
          xhr :get, :show, id: 11_111
        end

        describe '@user' do
          subject { assigns(:user) }
          it { is_expected.to eq(@mock_user) }
        end

        describe '@cr' do
          subject { assigns(:cr) }
          it { is_expected.to eq(@mock_credit_relation) }
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'show' }
        end
      end

      context 'with invalid id,' do
        before do
          @mock_user = users(:user1)
          @mock_credit_relations = double
          expect(User).to receive(:find).with(@mock_user.id).and_return(@mock_user)
          expect(@mock_user).to receive(:credit_relations).and_return(@mock_credit_relations)
          expect(@mock_credit_relations).to receive(:find).with('11111').and_raise(ActiveRecord::RecordNotFound.new)
          xhr :get, :show, id: 11_111
        end

        describe '@user' do
          subject { assigns(:user) }
          it { is_expected.to eq(@mock_user) }
        end

        describe 'response' do
          subject { response }
          it { is_expected.to redirect_by_js_to settings_credit_relations_url }
        end
      end
    end
  end

  describe '#edit' do
    context 'before login,' do
      before do
        xhr :get, :edit, id: 123_456
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'with valid method,' do
        context 'and with invalid id in params,' do
          before do
            mock_user = users(:user1)
            expect(User).to receive(:find).with(users(:user1).id).and_return(mock_user)
            mock_credit_relations = double
            expect(mock_user).to receive(:credit_relations).and_return(mock_credit_relations)
            expect(mock_credit_relations).to receive(:find).with('341341').and_raise(ActiveRecord::RecordNotFound.new)

            xhr :get, :edit, id: 341_341
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id: 'warning', default_errors: 'データが存在しません。' }
          end
        end

        context 'with correct id in params,' do
          before do
            mock_user = users(:user1)
            expect(User).to receive(:find).with(users(:user1).id).and_return(mock_user)
            mock_credit_relations = double
            expect(mock_user).to receive(:credit_relations).and_return(mock_credit_relations)
            @mock_credit_relation = mock_model(CreditRelation, id: 341_341)
            expect(mock_credit_relations).to receive(:find).with('341341').and_return(@mock_credit_relation)

            xhr :get, :edit, id: 341_341
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_template 'edit' }
          end

          describe '@cr' do
            subject { assigns(:cr) }
            it { is_expected.to eq(@mock_credit_relation) }
          end
        end
      end
    end
  end

  describe '#destroy' do
    context 'before login,' do
      before do
        xhr :delete, :destroy, id: 123_456
      end

      describe 'response' do
        it_should_behave_like 'Unauthenticated Access by xhr'
      end
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'with invalid id in params,' do
        before do
          @mock_user = users(:user1)
          mock_crs = double
          expect(User).to receive(:find).with(users(:user1).id).and_return(@mock_user)
          expect(@mock_user).to receive(:credit_relations).twice.and_return(mock_crs)
          expect(mock_crs).to receive(:destroy).with('123456').and_raise(ActiveRecord::RecordNotFound.new)
          @mock_crs_all = double
          expect(mock_crs).to receive(:all).and_return(@mock_crs_all)

          xhr :delete, :destroy, id: 123_456
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'no_record' }
        end

        describe '@user' do
          subject { assigns[:user] }
          it { is_expected.to be @mock_user }
        end

        describe '@credit_relations' do
          subject { assigns[:credit_relations] }
          it { is_expected.to be @mock_crs_all }
        end
      end

      context 'with valid id in params,' do
        before do
          @mock_user = users(:user1)
          mock_crs = double
          expect(User).to receive(:find).with(users(:user1).id).and_return(@mock_user)
          expect(@mock_user).to receive(:credit_relations).and_return(mock_crs)
          expect(mock_crs).to receive(:destroy).with('123456')
          @mock_crs_all = double
          expect(mock_crs).not_to receive(:all)

          xhr :delete, :destroy, id: 123_456
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'destroy' }
        end

        describe '@user' do
          subject { assigns[:user] }
          it { is_expected.to be @mock_user }
        end

        describe '@destroyed_id' do
          subject { assigns[:destroyed_id] }
          it { is_expected.to eq('123456') }
        end
      end
    end
  end

  describe '#create' do
    fixtures :accounts
    context 'before login,' do
      before do
        xhr :post, :create, credit_account_id: accounts(:bank21).id, payment_account_id:  accounts(:bank1).id, settlement_day: 99, payment_month: 1, payment_day: 4
      end

      subject { response }
      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'with valid_method,' do
        before do
          @mock_user = users(:user1)
          expect(User).to receive(:find).with(users(:user1).id).and_return(@mock_user)
          @mock_crs = double
          @mock_cr = mock_model(CreditRelation)
        end

        context 'with invalid params,' do
          before do
            expect(@mock_user).to receive(:credit_relations).and_return(@mock_crs)
            mock_cr = stub_model(CreditRelation)
            mock_exception = ActiveRecord::RecordInvalid.new(mock_cr)
            mock_record = double
            mock_errors = double
            expect(mock_exception).to receive(:record).and_return(mock_record)
            expect(mock_record).to receive(:errors).and_return(mock_errors)
            expect(mock_errors).to receive(:full_messages).and_return(%w(aaa bbb ccc))
            expect(@mock_crs).to receive(:create!).with(credit_account_id: '1', payment_account_id: '2', settlement_day: '99', payment_month: '1', payment_day: '4').and_raise(mock_exception)
            expect(@mock_crs).not_to receive(:all)

            xhr :post, :create, credit_account_id: 1, payment_account_id:  2, settlement_day: 99, payment_month: 1, payment_day: 4
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id: 'warning', errors: %w(aaa bbb ccc), default_message: I18n.t('error.input_is_invalid') }
          end

          describe '@user' do
            subject { assigns(:user) }
            it { is_expected.to be @mock_user }
          end
        end

        context 'with valid params,' do
          before do
            expect(@mock_user).to receive(:credit_relations).at_least(1).and_return(@mock_crs)
expect(@mock_crs).to receive(:create!).with(credit_account_id: '1', payment_account_id:  '2', settlement_day: '99', payment_month: '1', payment_day: '4').and_return(@mock_cr)
            expect(@mock_crs).to receive(:all).and_return(@mock_crs)
            xhr :post, :create, credit_account_id: 1, payment_account_id:  2, settlement_day: 99, payment_month: 1, payment_day: 4
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'create' }
          end

          describe '@credit_relations' do
            subject { assigns(:credit_relations) }
            it { is_expected.to be @mock_crs }
          end
        end
      end
    end
  end

  describe '#update' do
    context 'before login,' do
      before do
        xhr :put, :update, id: 1, credit_account_id: 2, payment_account_id: 3, settlement_day: 25, payment_month: 2, payment_day: 10
      end

      subject { response }
      it { is_expected.to redirect_by_js_to login_url }
    end

    context 'after login,' do
      before do
        @mock_user = mock_model(User, id: users(:user1).id)
        expect(User).to receive(:find).with(@mock_user.id).at_least(1).and_return(@mock_user)
        dummy_login
      end

      context 'with valid method,' do
        before do
          @mock_crs = double
          expect(@mock_user).to receive(:credit_relations).at_least(1).and_return(@mock_crs)
        end

        shared_examples_for 'Got basic instance variables successfully' do
          describe '@user' do
            subject { assigns(:user) }
            it { is_expected.to be @mock_user }
          end
        end

        context 'and invalid id in params,' do
          before do
            expect(@mock_crs).to receive(:find).with('1').and_raise(ActiveRecord::RecordNotFound.new)
            @mock_crs_all = [double, double]
            expect(@mock_crs).to receive(:all).and_return(@mock_crs_all)

            xhr :put, :update, id: 1, credit_account_id: 2, payment_account_id: 3, settlement_day: 25, payment_month: 2, payment_day: 10
          end

          it_should_behave_like 'Got basic instance variables successfully'

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'no_record' }
          end

          describe '@credit_relations' do
            subject { assigns(:credit_relations) }
            it { is_expected.to eq(@mock_crs_all) }
          end
        end

        context 'and validation error happens,' do
          before do
            @mock_cr = mock_model(CreditRelation, id: 1)
            expect(@mock_crs).to receive(:find).with('1').and_return(@mock_cr)
            expect(@mock_cr).to receive(:update_attributes!).with(credit_account_id: '2', payment_account_id: '3', settlement_day: '25', payment_month: '2', payment_day: '10').and_raise(ActiveRecord::RecordInvalid.new(@mock_cr))
            @mock_errors = [double, double, double]
            expect(@mock_cr).to receive(:errors).and_return(@mock_errors)

            xhr :put, :update, id: 1, credit_account_id: 2, payment_account_id: 3, settlement_day: 25, payment_month: 2, payment_day: 10
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id: 'edit_warning_1', errors: @mock_errors, default_message: I18n.t('error.input_is_invalid') }
          end

          it_should_behave_like 'Got basic instance variables successfully'

          describe '@cr' do
            subject { assigns(:cr) }
            it { is_expected.to be @mock_cr }
          end
        end

        context 'and valid requests,' do
          before do
            @mock_cr = mock_model(CreditRelation, id: 1)
            expect(@mock_crs).to receive(:find).with('1').and_return(@mock_cr)
            expect(@mock_cr).to receive(:update_attributes!).with(credit_account_id: '2', payment_account_id: '3', settlement_day: '25', payment_month: '2', payment_day: '10').and_return(true)

            xhr :put, :update, id: 1, credit_account_id: 2, payment_account_id: 3, settlement_day: 25, payment_month: 2, payment_day: 10
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'update' }
          end

          it_should_behave_like 'Got basic instance variables successfully'

          describe '@cr' do
            subject { assigns(:cr) }
            it { is_expected.to be @mock_cr }
          end
        end
      end
    end
  end
end
