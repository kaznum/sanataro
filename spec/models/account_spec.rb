# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account, type: :model do
  fixtures :users
  before do
    # Sometimes fixture of credit_relations remains, 
    # but this spec does not use their data but fabrication
    CreditRelation.destroy_all
    @valid_params = {
      name: 'aaaaa',
      order_no: 1,
    }
  end

  context 'when create,' do
    before  do
      @account = users(:user1).bankings.new(@valid_params)
    end

    context 'when all attributes are correct,' do
      describe '#save' do
        it { expect { @account.save! }.not_to raise_error }
      end
    end

    context 'when name is nil' do
      before do
        @account.name = nil
        @retval = @account.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors on :name' do
        subject { @account }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:name).size).to be >= 1
        end
      end
    end

    context 'when name is empty string,' do
      before do
        @account.name = ''
        @retval = @account.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors on :name' do
        subject { @account }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:name).size).to be >= 1
        end
      end
    end

    context 'when name length is 255,' do
      before do
        @account.name = 'a' * 255
      end

      it { expect { @account.save! }.not_to raise_error }
    end

    context 'when name length is larger than 255,' do
      before do
        @account.name = 'a' * 256
        @retval = @account.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors' do
        subject { @account }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:name).size).to be >= 1
        end
      end
    end

    context 'when account type is wrong,' do
      before do
        @acc = Account.new(@valid_params)
        @acc.type = 'invalid'
        @retval = @acc.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors' do
        subject { @acc }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:type).size).to be >= 1
        end
      end
    end

    context 'when account type is null,' do
      before do
        @acc = Account.new(@valid_params)
        @acc.type = nil
        @retval = @acc.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors' do
        subject { @acc }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:type).size).to be >= 1
        end
      end
    end

    context 'when bgcolor is exist,' do
      context 'and bgcolor does not have #,' do
        before do
          @acc = users(:user1).bankings.new(@valid_params)
          @acc.bgcolor = 'ff0f1f'
          @retval = @acc.save
        end

        describe 'returned value' do
          subject { @retval }
          it { is_expected.to be_truthy }
        end
      end

      context 'and bgcolor has #,' do
        before do
          @acc = users(:user1).bankings.new(@valid_params)
          @acc.bgcolor = '#ff0f1f'
          @retval = @acc.save
        end

        describe 'returned value' do
          subject { @retval }
          it { is_expected.to be_truthy }
        end

        describe '#bgcolor' do
          subject { @acc.bgcolor }
          it { is_expected.to eq('ff0f1f') }
        end
      end
    end

    context 'when bgcolor is exist but wrong' do
      before do
        @acc = users(:user1).bankings.new(@valid_params)
        @acc.bgcolor = 'f0f2fg'
        @retval = @acc.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors' do
        subject { @acc }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:bgcolor).size).to be >= 1
        end
      end
    end

    context 'when order_no is nil,' do
      before do
        @acc = users(:user1).bankings.new(@valid_params)
        @acc.order_no = nil
        @retval = @acc.save
      end

      describe 'returned value' do
        subject { @retval }
        it { is_expected.to be_falsey }
      end

      describe 'errors' do
        subject { @acc }
        it 'has at least 1 errors_on' do
          expect(subject.errors_on(:order_no).size).to be >= 1
        end
      end
    end
  end

  context 'when getting asset balance,' do
    fixtures :accounts, :items, :monthly_profit_losses

    context "when adjustment_id isn't specified" do
      subject {
        ini_bank1 = accounts(:bank1)
        date = items(:item5).action_date
        user = users(:user1)
        user.accounts.asset(user, ini_bank1.id, date)
      }
      it { is_expected.to eq(13_900) }
    end

    context 'when specifying adj_id whose action_date is same as that of original adj_id,' do
      subject {
        user = users(:user1)
        ini_bank1 = accounts(:bank1)
        date = items(:adjustment4).action_date.clone
        user.accounts.asset(user, ini_bank1.id, date, items(:adjustment4).id)
      }
      it { is_expected.to eq(15_000) }
    end

    context "when specifying id which is same as the account of from_account_id = bank1's id(action_date = adjustment4.action_date + 1day)," do
      subject {
        user = users(:user1)
        ini_bank1 = accounts(:bank1)
        date = items(:adjustment4).action_date.clone + 1
        user.accounts.asset(user, ini_bank1.id, date, items(:item3).id)
      }
      it { is_expected.to eq(19_000) }
    end

    context 'when specifying adj_id whose action_date is after that of adj_id,' do
      let(:user) { users(:user1) }
      subject {
        user.accounts.asset(user,
                            accounts(:bank1).id,
                            items(:adjustment6).action_date + 1,
                            items(:adjustment4).id)
      }
      it { is_expected.to eq(13_900) }
    end
  end

  describe '#credit_due_date' do
    before do
      @credit_params = {
        name: 'credit',
        order_no: 1
      }

      @bank_params = {
        name: 'bank',
        order_no: 10,
      }

      @relation_params = {
        settlement_day: 10,
        payment_month: 2,
        payment_day: 4,
      }

      @credit = users(:user1).bankings.create!(@credit_params)
      @bank = users(:user1).bankings.create!(@bank_params)
      @relation = users(:user1).credit_relations.create!(@relation_params.merge(credit_account_id: @credit.id, payment_account_id: @bank.id))
    end

    context 'when action_date is before the settlemnt_date,' do
      subject { @credit.credit_due_date(Date.new(2011, 2, 5)) }
      it { is_expected.to eq(Date.new(2011, 4, 4)) }
    end

    context 'when action_date is after the settlemnt_date,' do
      subject { @credit.credit_due_date(Date.new(2011, 2, 15)) }
      it { is_expected.to eq(Date.new(2011, 5, 4)) }
    end

    context 'when payment_day is 99,' do
      before do
        @relation.update_attributes!(@relation_params.merge(credit_account_id: @credit.id, payment_account_id: @bank.id, payment_day: 99))
      end

      context 'when the action_date is before the settlement_date 5,' do
        subject { @credit.credit_due_date(Date.new(2011, 7, 5)) }
        it { is_expected.to eq(Date.new(2011, 9, 30)) }
      end

      context 'when end_of_month is 31,' do
        subject { @credit.credit_due_date(Date.new(2011, 7, 31)) }
        it { is_expected.to eq(Date.new(2011, 10, 31)) }
      end

      context 'when end_of_month is 28,' do
        subject { @credit.credit_due_date(Date.new(2011, 2, 28)) }
        it { is_expected.to eq(Date.new(2011, 5, 31)) }
      end
    end
  end

  describe '#destroy' do
    context "when child items/credit_relations don't exist," do
      before do
        Item.destroy_all
        CreditRelation.destroy_all
        account = Fabricate.build(:banking)
        account.save!
        @account = Account.find(account.id)
      end

      describe 'count' do
        it { expect { @account.destroy }.to change { Account.count }.by(-1) }
      end
      describe '#errors' do
        before { @account.destroy }
        subject { @account.errors.full_messages }
        it { is_expected.to be_empty }
      end
    end

    context 'when child items exist,' do
      fixtures :accounts
      before do
        @account = Fabricate.build(:banking)
        @account.save!
      end

      context 'when it is used for from_account_id,' do
        before do
          item = Fabricate.build(:general_item, from_account_id: @account.id)
          item.save!
        end

        describe 'count' do
          it { expect { @account.destroy }.not_to change { Account.count } }
        end

        describe '#errors' do
          before { @account.destroy }
          subject { @account.errors.full_messages }
          it { is_expected.not_to be_empty }
        end
      end

      context 'when it is used for to_account_id,' do
        before do
          item = Fabricate.build(:general_item, to_account_id: @account.id)
          item.save!
        end

        describe 'count' do
          it { expect { @account.destroy }.not_to change { Account.count } }
        end

        describe '#errors' do
          before { @account.destroy }
          subject { @account.errors.full_messages }
          it { is_expected.not_to be_empty }
        end
      end
    end

    context 'when child credit_relations exist,' do
      before do
        @account = Fabricate.build(:banking)
        @account.save!
      end

      context 'when it is used for payment_account_id,' do
        before do
          cr = Fabricate.build(:credit_relation, payment_account_id: @account.id)
          cr.save!
        end

        describe 'count' do
          it { expect { @account.destroy }.not_to change { Account.count } }
        end
      end

      context 'when it is used for credit_account_id,' do
        before do
          cr = Fabricate.build(:credit_relation, credit_account_id: @account.id)
          cr.save!
        end

        describe 'count' do
          it { expect { @account.destroy }.not_to change { Account.count } }
        end

        describe '#errors' do
          before { @account.destroy }
          subject { @account.errors.full_messages }
          it { is_expected.not_to be_empty }
        end
      end
    end
  end
end
