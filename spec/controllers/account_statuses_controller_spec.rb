require 'spec_helper'

describe AccountStatusesController, type: :controller do
  fixtures :users, :items, :accounts, :monthly_profit_losses

  describe '#show' do
    context 'when not logined,' do
      specify do
        expect(User).to receive(:find).with(nil).once.and_raise(ActiveRecord::RecordNotFound)
        xhr :get, :show
      end
    end

    context 'when logined,' do
      before do
        dummy_login
        xhr :get, :show
      end

      describe 'response' do
        before { xhr :get, :show }

        subject { response }
        it { is_expected.to render_template('account_statuses/show') }
      end

      describe '@account_statuses' do
        before do
          users(:user1).general_items.create!(from_account_id: -1, to_account_id: accounts(:bank1).id, amount: -100, action_date: Date.today, name: 'unknown')
          xhr :get, :show
        end

        subject { assigns(:account_statuses) }
        it { is_expected.not_to be_empty }

        describe '[:bankings]' do
          subject { super()[:bankings] }
          it { is_expected.not_to be_nil }
        end

        describe '[:expenses]' do
          subject { super()[:expenses] }
          it { is_expected.not_to be_nil }
        end

        describe '[:incomes]' do
          subject { super()[:incomes] }
          it { is_expected.not_to be_nil }
        end

        describe 'unknown account' do
          it 'does exist and amount is 100' do
            expensees = assigns(:account_statuses)[:expenses]
            matches = expensees.select { |account, amount| account.name == I18n.t('label.unknown') }
            expect(matches.entries.size).to eq(1)
            expect(matches[0][1]).to eq(100)
          end
        end
      end
    end
  end
end
