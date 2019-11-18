require 'spec_helper'

describe ChartData::BudgetsController, type: :controller do
  fixtures :users

  describe '#show' do
    context 'before login,' do
      before do
        get :show, id: 200_802, format: :json
      end

      it_should_behave_like 'Unauthenticated Access'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context "when id's length is not 6 digit," do
        before do
          get :show, id: '21222', format: :json
        end

        it_should_behave_like 'Not Acceptable'
      end

      context "when id's initial char is not 0," do
        before do
          get :show, id: '021222', format: :json
        end

        it_should_behave_like 'Not Acceptable'
      end

      context 'when id has non-numeric char,' do
        before do
          get :show, id: '2008a2', format: :json
        end

        it_should_behave_like 'Not Acceptable'
      end

      context 'when id does not mean correct year-month,' do
        before do
          get :show, id: '200815', format: :json
        end

        it_should_behave_like 'Not Acceptable'
      end

      context 'When there is no data to send,' do
        before do
          Account.destroy_all
          get :show, id: '200301', format: :json
        end
        subject { response }
        it { is_expected.to be_success }

        describe '#body' do
          subject { super().body }
          it { is_expected.to eq('[]') }
        end
      end

      context 'When there are data to send,' do
        before do
          Account.destroy_all
          @user = users(:user1)
          account1 = @user.bankings.create!(name: 'その1', active: true, order_no: 10)
          account2 = @user.incomes.create!(name: 'その2', active: true, order_no: 20)
          account3 = @user.bankings.create!(name: 'その3', active: true, order_no: 30)
          account4 = @user.expenses.create!(name: 'その4', active: true, order_no: 40)

          @user.monthly_profit_losses.create!(month: Date.new(1999, 5), account_id: account1.id, amount: -300)
          @user.monthly_profit_losses.create!(month: Date.new(1988, 6), account_id: account1.id, amount: -100)
          @user.monthly_profit_losses.create!(month: Date.new(1999, 1), account_id: account2.id, amount: -900)
          @user.monthly_profit_losses.create!(month: Date.new(1999, 1), account_id: account3.id, amount: 900)
          @user.monthly_profit_losses.create!(month: Date.new(1999, 1), account_id: account4.id, amount: 200)
          @mpl_unknown = @user.monthly_profit_losses.create!(month: Date.new(1999, 1), account_id: -1, amount: -800)
        end

        context 'when budget_type is not specified,' do
          before do
            get :show, id: '199901', format: :json
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            specify do
              expect(ActiveSupport::JSON.decode(subject.body)).to eq([{ 'label' => 'その2', 'data' => 900 }, { 'label' => I18n.t('label.unknown_income'), 'data' => 800 }])
            end
          end
        end

        context "when budget_type is 'expense'," do
          before do
            @mpl_unknown.update_attributes(amount: 500)

            get :show, id: '199901', format: :json, budget_type: 'expense'
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            specify do
              expect(ActiveSupport::JSON.decode(subject.body)).to eq([{ 'label' => 'その4', 'data' => 200 }, { 'label' => I18n.t('label.unknown_expense'), 'data' => 500 }])
            end
          end
        end
      end
    end
  end
end
