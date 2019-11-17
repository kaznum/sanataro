require 'spec_helper'

describe User, :type => :model do
  fixtures :users, :items, :accounts, :credit_relations

  describe '#create' do
    before do
      valid_attrs = {
        password_plain: '123-4_56',
        password_confirmation: '123-4_56',
        email: 'test@hoge.example.com'
      }
      @user = User.new(valid_attrs)
      @user.login = 'test_1'
    end

    context 'when all attributes are valid,' do
      subject {
        @user.save
        @user
      }

      it { is_expected.not_to be_new_record }

      describe '#password' do
        subject { super().password }
        it { is_expected.to eq(Digest::SHA1.hexdigest('test_1' + '123-4_56')) }
      end

      describe '#created_at' do
        subject { super().created_at }
        it { is_expected.not_to be_nil }
      end

      describe '#updated_at' do
        subject { super().updated_at }
        it { is_expected.not_to be_nil }
      end

      describe '#active?' do
        subject { super().active? }
        it { is_expected.to be_truthy }
      end
    end

    context 'when without email,' do
      subject {
        @user.email = ''
        @user.save
        @user
      }
      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:email]).not_to be_empty }
    end

    describe 'when email is formatted wrong,' do
      subject {
        @user.email = 'test.example.com'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:email]).not_to be_empty }
    end

    context 'when email is too short,' do
      subject {
        @user.email = 't@e.c'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:email]).not_to be_empty }
    end

    context 'when password_plain and password_confirmation are not same,' do
      subject {
        @user.password_confirmation = 'ddddddddd'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:password_plain]).not_to be_empty }
    end

    context 'when login is not set,' do
      subject {
        @user.login = nil
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:login]).not_to be_empty }
    end

    context 'when login is too short,' do
      subject {
        @user.login = '11'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:login]).not_to be_empty }
    end

    context 'when login is too long,' do
      subject {
        @user.login = '12345678901'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:login]).not_to be_empty }
    end

    describe 'when both of passwords are not set' do
      subject {
        @user.password_plain = nil
        @user.password_confirmation = nil
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:password_plain]).not_to be_empty }
    end

    context 'when both of passwords are too short,' do
      subject {
        @user.password_plain = '12345'
        @user.password_confirmation = '12345'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:password_plain]).not_to be_empty }
    end

    context 'when both of passwords are too long,' do
      subject {
        @user.password_plain = '12345678901'
        @user.password_confirmation = '12345678901'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:password_plain]).not_to be_empty }
    end

    context 'when both of passwords have invalid chars,' do
      subject {
        @user.password_plain = '1234.56'
        @user.password_confirmation = '1234.56'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:password_plain]).not_to be_empty }
    end

    context 'when login has invalid chars,' do
      subject {
        @user.login = 'te.st1'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:login]).not_to be_empty }
    end

    context 'when login is not unique,' do
      subject {
        @user.login = 'user1'
        @user.save
        @user
      }

      it { is_expected.to be_new_record }
      specify { expect(subject.errors[:login]).not_to be_empty }
    end
  end

  describe '#update' do
    before do
      @old_user = User.find(1)
      @user = User.find(1)
    end

    context 'when password changed correctly,' do
      subject {
        @user.password_plain = '12-3456'
        @user.password_confirmation = '12-3456'
        @user.save
        @user
      }

      specify { expect(subject.errors[:password_plain]).to be_empty }

      describe '#updated_at' do
        subject { super().updated_at }
        it { is_expected.to be > @old_user.updated_at }
      end
    end

    context 'when without_password' do
      subject {
        @user.password_plain = ''
        @user.password_confirmation = ''
        @user.login
        @user
      }

      specify { expect(subject.errors).to be_empty }

      describe '#updated_at' do
        subject { super().updated_at }
        it { is_expected.to eq(@old_user.updated_at) }
      end
    end
  end

  describe 'associations' do
    describe 'it has accounts' do
      subject { users(:user1).accounts }
      it { is_expected.not_to be_empty }
    end

    context 'when it has credit_relations,' do
      subject { users(:user1).credit_relations }
      it { is_expected.not_to be_empty }
    end

    context 'when it has items' do
      subject { users(:user1).items }

      it { is_expected.not_to be_empty }
      specify {
        subject.each do |item|
          expect(item).not_to be_nil
        end
      }

      specify {
        expect(subject.where('action_date < ?', Date.new(2008, 3)).to_a).not_to be_empty
      }
      specify {
        expect(subject.where(user_id: 101).to_a.size).to eq(0)
      }
      specify {
        expect(subject.where(user_id: 1).size).to be > 0
      }
    end
  end

  describe '#from_accounts' do
    let(:user) { users(:user1) }

    describe 'size' do
      let(:actual) { user.accounts.where(type: %w(Banking Income)) }
      subject { user.from_accounts }
      it 'has actual.size records' do
        expect(subject.size).to eq(actual.size)
      end
    end

    describe 'entities' do
      let(:bankings) { user.bankings.map { |a| [a.name, a.id.to_s] } }
      let(:incomes) { user.incomes.map { |a| [a.name, a.id.to_s] } }
      subject { user.from_accounts }
      it { is_expected.to eq(bankings + incomes) }
    end
  end

  describe '#to_accounts' do
    let(:user) { users(:user1) }
    describe 'size' do
      let(:actual) { user.accounts.where(type: %w(Banking Expense)) }
      subject { user.to_accounts }
      it 'has actual.size records' do
        expect(subject.size).to eq(actual.size)
      end
    end

    describe 'entities' do
      let(:expenses) { user.expenses.map { |a| [a.name, a.id.to_s] } }
      let(:bankings) { user.bankings.map { |a| [a.name, a.id.to_s] } }
      subject { user.to_accounts }
      it { is_expected.to eq(expenses + bankings) }
    end
  end

  describe '#bank_accounts' do
    let(:user) { users(:user1) }
    let(:actual) { user.bankings }
    subject { user.bank_accounts }
    it 'has actual.size records' do
      expect(subject.size).to eq(actual.size)
    end

    describe '#sort' do
      subject { super().sort }
      it { is_expected.to eq(actual.map { |a| [a.name, a.id.to_s] }.sort) }
    end
  end

  describe '#all_accounts' do
    let(:user) { users(:user1) }
    subject { user.all_accounts }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(user.accounts.size) }
    end
  end

  describe '#account_bgcolors' do
    let(:user) { users(:user1) }
    subject { user.account_bgcolors }
    it 'has user.accounts.where("bgcolor IS NOT NULL").size records' do
      expect(subject.size).to eq(user.accounts.where('bgcolor IS NOT NULL').size)
    end
  end

  shared_examples_for 'a method for ids of accounts' do |name|
    describe 'accounts' do
      let(:user) { users(:user1) }
      let(:type) { name.pluralize.to_sym }
      subject { user.send("#{name}_ids".to_sym) }

      describe '#size' do
        subject { super().size }
        it { is_expected.to eq(user.send(type).active.size) }
      end

      describe '#sort' do
        subject { super().sort }
        it { is_expected.to eq(user.send(type).active.pluck(:id).sort) }
      end
    end
  end

  %w(income expense banking).each do |name|
    describe "##{name}_ids" do
      it_should_behave_like 'a method for ids of accounts', name
    end
  end

  describe '#deliver_signup_confirmation' do
    let(:user) { User.new }
    specify {
      mock_obj = double
      expect(mock_obj).to receive(:deliver_now)
      expect(Mailer).to receive(:signup_confirmation).with(user).and_return(mock_obj)
      user.deliver_signup_confirmation
    }
  end

  describe '#deliver_signup_complete' do
    let(:user) { User.new }
    specify {
      mock_obj = double
      expect(mock_obj).to receive(:deliver_now)
      expect(Mailer).to receive(:signup_complete).with(user).and_return(mock_obj)
      user.deliver_signup_complete
    }
  end

  describe '#store_sample' do
    describe 'called methods' do
      before do
        @user = Fabricate(:user)
      end

      specify {
        expect(@user).to receive(:bankings).exactly(4).times.and_return(@mock_bankings = double([Banking]))
        expect(@user).to receive(:incomes).exactly(3).times.and_return(@mock_incomes = double([Income]))
        expect(@user).to receive(:expenses).exactly(6).times.and_return(@mock_expenses = double([Expense]))
        expect(@user).to receive(:credit_relations).once.and_return(@mock_crs = double([CreditRelation]))
        expect(@user).to receive(:general_items).twice.and_return(@mock_items = double([GeneralItem]))
        expect(@mock_bankings).to receive(:create!).exactly(4).times.and_return(@banking = double(Banking))
        expect(@mock_incomes).to receive(:create!).exactly(3).times.and_return(@income = double(Income))
        expect(@mock_expenses).to receive(:create!).exactly(6).times.and_return(@expense = double(Expense))
        expect(@banking).to receive(:id).exactly(4).times.and_return(100)
        expect(@income).to receive(:id).exactly(1).times.and_return(200)
        expect(@expense).to receive(:id).exactly(1).times.and_return(300)
        expect(@mock_crs).to receive(:create!).once.times
        expect(@mock_items).to receive(:create!).twice

        @user.store_sample
      }
    end
    describe 'no error' do
      before do
        @user = Fabricate(:user)
        @user.save!
      end

      specify {
        expect { @user.store_sample }.not_to raise_error
      }
    end
  end
end
