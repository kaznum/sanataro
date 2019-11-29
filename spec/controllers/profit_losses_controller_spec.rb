# frozen_string_literal: true

require 'spec_helper'

describe ProfitLossesController, type: :controller do
  fixtures :users, :items, :accounts, :monthly_profit_losses, :credit_relations

  describe '#index' do
    context 'when not logged in,' do
      before do
        get :index
      end

      it_should_behave_like 'Unauthenticated Access'
    end

    context 'when logged in,' do
      before do
        dummy_login
      end
      context 'when month is not specified,' do
        before do
          get :index
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_successful }
          it { is_expected.to render_template('index') }
        end

        describe 'instance varriables' do
          subject { assigns }

          describe '[:m_pls]' do
            subject { super()[:m_pls] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_incomes]' do
            subject { super()[:account_incomes] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_income]' do
            subject { super()[:total_income] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_expenses]' do
            subject { super()[:account_expenses] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_expense]' do
            subject { super()[:total_expense] }
            it { is_expected.not_to be_nil }
          end
        end
      end

      context 'when month is invalid,' do
        before do
          get :index, year: '2008', month: '13'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to redirect_to current_entries_url }
        end
      end

      context 'when valid month is specified,' do
        context 'and with common condition,' do
          before do
            get :index, year: '2008', month: '2'
          end
          describe 'response' do
            subject { response }
            it { is_expected.to be_successful }
            it { is_expected.to render_template('index') }
          end

          describe 'assigned variables' do
            subject { assigns }

            describe '[:m_pls]' do
              subject { super()[:m_pls] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_incomes]' do
              subject { super()[:account_incomes] }
              it { is_expected.not_to be_nil }
            end

            describe '[:total_income]' do
              subject { super()[:total_income] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_expenses]' do
              subject { super()[:account_expenses] }
              it { is_expected.not_to be_nil }
            end

            describe '[:total_expense]' do
              subject { super()[:total_expense] }
              it { is_expected.not_to be_nil }
            end
          end
        end

        context 'and Unknown accounts amount < 0,' do
          before do
            get :index, year: '2008', month: '2'
          end

          describe 'unknown account in assigned variables' do
            subject { assigns[:account_incomes] }
            it { is_expected.to be_any { |a| a.id == -1 } }
            specify { expect(subject.find { |a| a.id == -1 }.name).to eq(I18n.t('label.unknown_income')) }
          end
        end

        context 'and Unknown accounts amount > 0,' do
          before do
            MonthlyProfitLoss.find(ActiveRecord::FixtureSet.identify(:unknown200802)).update_attributes(amount: 5000)
            get :index, year: '2008', month: '2'
          end

          describe 'unknown account in assigned variables' do
            subject { assigns[:account_expenses] }
            it { is_expected.to be_any { |a| a.id == -1 } }
            specify { expect(subject.find { |a| a.id == -1 }.name).to eq(I18n.t('label.unknown_expense')) }
          end
        end
      end
    end
  end

  describe '#show' do
    context 'when not logged in,' do
      before do
        xhr :get, :show, id: accounts(:bank1).id, year: '2008', month: '2'
      end

      describe 'response' do
        subject { response }
        it { is_expected.to render_template('common/redirect') }
      end
    end

    context 'when logged in,' do
      before do
        dummy_login
      end

      context 'when correct id is specified,' do
        context 'when year, month are specified,' do
          before do
            xhr :get, :show, id: accounts(:expense3).id.to_s, year: '2008', month: '2'
          end
          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'show' }
          end

          describe 'assigned variables' do
            subject { assigns }

            describe '[:items]' do
              subject { super()[:items] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_id]' do
              subject { super()[:account_id] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_id]' do
              subject { super()[:account_id] }
              it { is_expected.to be accounts(:expense3).id }
            end

            describe 'items' do
              subject { assigns[:items] }
              specify do
                subject.each do |item|
                  expect(item.to_account_id).to be(accounts(:expense3).id)
                  expect(item.action_date).to be_between(Date.new(2008, 2), Date.new(2008, 2).end_of_month)
                end
              end
            end
          end
        end

        context 'when year, month are not specified,' do
          before do
            xhr :get, :show, id: accounts(:expense3).id.to_s
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_successful }
            it { is_expected.to render_template 'show' }
          end
          describe 'assigned variables' do
            subject { assigns }

            describe '[:items]' do
              subject { super()[:items] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_id]' do
              subject { super()[:account_id] }
              it { is_expected.not_to be_nil }
            end

            describe '[:account_id]' do
              subject { super()[:account_id] }
              it { is_expected.to be accounts(:expense3).id }
            end

            describe 'items' do
              subject { assigns(:items) }
              specify do
                subject.each do |item|
                  expect(item.to_account_id).to be accounts(:expense3).id
                  expect(item.action_date).to be_between(Date.today.beginning_of_month, Date.today.end_of_month)
                end
              end
            end
          end
        end
      end
    end
  end
end
