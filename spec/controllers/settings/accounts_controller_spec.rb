# -*- coding: utf-8 -*-
require 'spec_helper'

describe Settings::AccountsController, :type => :controller do
  fixtures :all

  describe '#index' do
    context 'before login,' do
      before do
        get :index, type: nil
      end

      it_should_behave_like 'Unauthenticated Access'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when params[:type] is invalid,' do
        before do
          get :index, type: 'not_exist'
        end

        it_should_behave_like 'Unauthenticated Access'

        describe '@accounts' do
          subject { assigns(:accounts) }
          it { is_expected.to be_nil }
        end
      end

      [:banking, :expense, :income].each do |type|
        shared_examples_for "type = '#{type}'" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template('index') }

          describe '@type' do
            subject { assigns(:type) }
            it { is_expected.to eq(type) }
          end

          describe '@accounts' do
            subject { assigns(:accounts) }
            it { is_expected.not_to be_empty }
            specify {
              subject.each do |a|
                expect(a.type).to eq(type.to_s.capitalize)
              end
            }
          end
        end
      end

      context 'when params[:type] is nil,' do
        before do
          get :index, type: nil
        end
        it_should_behave_like "type = 'banking'"
      end

      context "when params[:type] == 'banking'," do
        before do
          get :index, type: 'banking'
        end
        it_should_behave_like "type = 'banking'"
      end

      context "when params[:type] == 'expense'," do
        before do
          get :index, type: 'expense'
        end

        it_should_behave_like "type = 'expense'"
      end

      context "when params[:type] == 'income'," do
        before do
          get :index, type: 'income'
        end

        it_should_behave_like "type = 'income'"
      end
    end
  end

  describe '#create' do

    context 'before login,' do
      before do
        xhr :post, :create, type: 'banking', account_name:  'hogehoge', order_no: '10'
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'via xhr,' do
        context 'with valid params,' do
          before do
            @before_count = Account.count
            @before_bgcolors_count = User.find(session[:user_id]).account_bgcolors.size
            xhr :post, :create, type: 'banking', account_name:  'hogehoge', order_no: '10'
          end

          describe 'response' do
            subject { response }
            it { is_expected.to redirect_by_js_to settings_accounts_url(type: 'banking') }
          end

          describe 'count of accounts' do
            subject { Account.count }
            it { is_expected.to eq(@before_count + 1) }
          end

          describe 'count of bgcolors' do
            subject { User.find(session[:user_id]).account_bgcolors.size }
            it { is_expected.to eq(@before_bgcolors_count) }
          end
        end

        context 'with invalid params,' do
          before do
            @before_count = Account.count
            @before_bgcolors_count = User.find(session[:user_id]).account_bgcolors.size
            xhr :post, :create, type: 'account', account_name:  'hogehoge', order_no: '10'
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id: 'add_warning', default_message: I18n.t('error.input_is_invalid') }
          end

          describe 'count of accounts' do
            subject { Account.count }
            it { is_expected.to eq(@before_count) }
          end

          describe 'count of bgcolors' do
            subject { User.find(session[:user_id]).account_bgcolors.size }
            it { is_expected.to eq(@before_bgcolors_count) }
          end
        end
      end
    end
  end

  describe '#edit' do
    context 'before login,' do
      before do
        xhr :get, :edit, id: accounts(:bank1).id
      end

      subject { response }
      it { is_expected.to redirect_by_js_to login_url }
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when method is xhr get,' do

        context 'with invalid params[:id],' do
          before do
            xhr :get, :edit, id: 4_321_431
          end

          subject { response }
          it { is_expected.to redirect_by_js_to login_url }
        end

        context 'with valid params[:id],' do
          before do
            xhr :get, :edit, id: accounts(:bank1).id
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'edit' }
          end

          describe '@account' do
            subject { assigns(:account) }

            describe '#id' do
              subject { super().id }
              it { is_expected.to eq(accounts(:bank1).id) }
            end
          end
        end
      end
    end
  end

  describe '#destroy' do
    before do
      @dummy = users(:user1).bankings.create!(name: 'hogehoge', order_no: 100)
    end
    context 'before login,' do
      before do
        xhr :delete, :destroy, id: @dummy.id
      end
      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to login_url }
      end
    end

    context 'after login' do
      before do
        dummy_login
      end

      context 'when method is xhr delete,' do
        context 'when params[:id] is not correct,' do
          before do
            xhr :delete, :destroy, id: 31_432_412
          end
          it_should_behave_like 'Unauthenticated Access by xhr'
        end

        context 'when the account is not used yet,' do
          before do
            Item.destroy_all
            CreditRelation.destroy_all
            @action = -> { xhr :delete, :destroy, id: @dummy.id }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to render_template 'destroy' }
          end

          describe 'Account.count' do
            it { expect { @action.call }.to change { Account.count }.by(-1) }
          end
        end

        context 'when the account is already used,' do
          before do
            @action = -> { xhr :delete, :destroy, id: accounts(:bank1).id }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to render_js_error id: 'add_warning' }
          end

          describe 'Account.count' do
            it { expect { @action.call }.not_to change { Account.count } }
          end
        end

        context 'when the account has relation to credit card,' do
          before do
            Item.destroy_all
            account = accounts(:bank1)
            @action = -> { xhr :delete, :destroy, id: account.id }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to render_js_error id: 'add_warning', errors: ['クレジットカード支払い情報に関連づけられているため、削除できません。'] }
          end

          describe 'Account.count' do
            it { expect { @action.call }.not_to change { Account.count } }
          end
        end
      end
    end
  end

  describe '#update' do
    context 'before login,' do
      before do
        xhr :put, :update, id: accounts(:bank1).id, account_name:  'hogehoge', order_no: '10', bgcolor: '222222'
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'with xhr put method,' do

        context 'with invalid params[:id],' do
          before do
            xhr :put, :update, id: 4_314_321, account_name:  'hogehoge', order_no: '100', bgcolor: 'cccccc', use_bgcolor: '1'
          end

          it_should_behave_like 'Unauthenticated Access by xhr'
        end

        shared_examples_for 'Updated Successfully' do
          describe 'response' do
            subject { response }
            it { is_expected.to redirect_by_js_to settings_accounts_url(type: 'banking') }
          end

          describe '@user.all_accounts' do
            describe '@user.all_accounts[id]' do
              subject { assigns(:user).all_accounts[accounts(:bank1).id] }
              it { is_expected.to eq('hogehoge') }
            end

          end

          describe 'updated account record' do
            subject { Account.find(accounts(:bank1).id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('hogehoge') }
            end

            describe '#type' do
              subject { super().type }
              it { is_expected.to eq('Banking') }
            end

            describe '#order_no' do
              subject { super().order_no }
              it { is_expected.to be 100 }
            end
          end
        end

        context 'with valid params,' do
          context 'with bgcolor,' do
            before do
              xhr :put, :update, id: accounts(:bank1).id, account_name: 'hogehoge', order_no: '100', bgcolor: 'cccccc', use_bgcolor: '1'
            end

            it_should_behave_like 'Updated Successfully'

            describe 'assigns(:user).account_bgcolors[id]' do
              subject { assigns(:user).account_bgcolors[accounts(:bank1).id] }
              it { is_expected.to eq('cccccc') }
            end

            describe 'updated account record' do
              subject { Account.find(accounts(:bank1).id) }

              describe '#bgcolor' do
                subject { super().bgcolor }
                it { is_expected.to eq('cccccc') }
              end
            end
          end

          context 'without use_bgcolor,' do
            before do
              xhr :put, :update, id: accounts(:bank1).id, account_name: 'hogehoge', order_no: '100',  bgcolor: 'cccccc'
            end

            it_should_behave_like 'Updated Successfully'

            describe 'assigns(:user).account_bgcolors[id]' do
              subject { assigns(:user).account_bgcolors[accounts(:bank1).id] }
              it { is_expected.to be_nil }
            end

            describe 'updated account record' do
              subject { Account.find(accounts(:bank1).id) }

              describe '#bgcolor' do
                subject { super().bgcolor }
                it { is_expected.to be_nil }
              end
            end
          end
        end

        context 'with invalid params(name is empty),' do
          before do
            @orig_account = Account.find(accounts(:bank1).id)
            xhr :put, :update, id:  accounts(:bank1).id, account_name: '', order_no: '100', bgcolor: 'cccccc', use_bgcolor: '1'
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_js_error id:  "account_#{accounts(:bank1).id}_warning", default_message: I18n.t('error.input_is_invalid') }
          end

          describe 'DB Record' do
            subject { Account.find(accounts(:bank1).id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq(@orig_account.name) }
            end

            describe '#order_no' do
              subject { super().order_no }
              it { is_expected.to eq(@orig_account.order_no) }
            end

            describe '#type' do
              subject { super().type }
              it { is_expected.to eq(@orig_account.type) }
            end

            describe '#bgcolor' do
              subject { super().bgcolor }
              it { is_expected.to eq(@orig_account.bgcolor) }
            end
          end
        end
      end
    end
  end

  describe '#show' do
    context 'before login,' do
      before do
        xhr :get, :show, id:  accounts(:bank1).id
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when accessed by xhr get,' do
        context 'with valid params,' do
          before do
            xhr :get, :show, id:  accounts(:bank1).id
          end

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'show' }
          end

          describe '@account' do
            subject { assigns(:account) }
            it { is_expected.not_to be_nil }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq(accounts(:bank1).name) }
            end
          end
        end

        context 'with the invalid params[:id],' do
          before do
            xhr :get, :show, id: 992_143
          end

          subject { response }
          it { is_expected.to redirect_by_js_to login_url }
        end
      end
    end
  end
end
