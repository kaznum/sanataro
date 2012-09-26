require 'spec_helper'

describe CreditRelation do
  fixtures :credit_relations, :accounts, :users

  before do
    @valid_attrs = {
      :credit_account_id => accounts(:bank21).id,
      :payment_account_id => accounts(:bank1).id,
      :settlement_day => 25,
      :payment_month => 2,
      :payment_day => 10
    }
  end

  context "when create is called" do
    describe "create successfully" do
      before do
        @init_count = CreditRelation.count
        @cr = users(:user1).credit_relations.new(@valid_attrs)
        @cr.save
      end

      describe "created object" do
        subject { @cr }
        it { should have(0).errors }
        it { should_not be_new_record }
      end

      describe "count of records" do
        subject {CreditRelation.count}
        it { should be @init_count + 1 }
      end

      describe "regotten object" do
        subject { CreditRelation.find(@cr.id) }
        its(:credit_account_id) { should be accounts(:bank21).id }
        its(:payment_account_id) { should be accounts(:bank1).id }
        its(:settlement_day) { should be 25 }
        its(:payment_month) { should be 2 }
        its(:payment_day) { should be 10 }
      end
    end

    shared_examples "saving invalid param" do |attr|
      describe "returned value" do
        subject { @retval }
        it { should be_false }
      end

      describe "errors" do
        subject { @cr.errors[attr] }
        it { should_not be_empty }
      end

      describe "count of records" do
        subject { CreditRelation.count }
        it { should be @init_count }
      end
    end

    context "when create same account" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_account_id] = @valid_attrs[:credit_account_id]
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      it_should_behave_like "saving invalid param", :credit_account_id
    end

    context "when create same account" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_account_id] = @valid_attrs[:credit_account_id]
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      it_should_behave_like "saving invalid param", :credit_account_id
    end

    context "when creating the credit_relation whose credit_account is used as payment_account," do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:credit_account_id] = accounts(:bank1).id
        @invalid_attrs[:payment_account_id] = accounts(:bank11).id
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      it_should_behave_like "saving invalid param", :credit_account_id
    end

    context "when creating the credit_relation whose payment_account is used as credit_account," do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:credit_account_id] = accounts(:bank11).id
        @invalid_attrs[:payment_account_id] = accounts(:credit4).id
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      it_should_behave_like "saving invalid param", :payment_account_id
    end

    context "when create as same month" do
      context "settlement_day is larger than payment_day" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_month] = 0
          @invalid_attrs[:payment_day] = 15
          @invalid_attrs[:settlement_day] = 20

          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it_should_behave_like "saving invalid param", :settlement_day
      end

      context "settlement_day is smaller than payment_day" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_month] = 0
          @invalid_attrs[:payment_day] = 20
          @invalid_attrs[:settlement_day] = 15

          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end
        subject { @retval }

        it { should be_true }
      end
    end

    context "when settlement_day is invalid" do
      context "when settlement_day is 0" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:settlement_day] = 0
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it_should_behave_like "saving invalid param", :settlement_day
      end

      context "when settlement_day is greater than 28" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:settlement_day] = 29
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @rtval = @cr.save
        end
        it_should_behave_like "saving invalid param", :settlement_day
      end
    end

    context "when payment_month is invalid" do
      context "when payment_month is -1" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_month] = -1
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end
        it_should_behave_like "saving invalid param", :payment_month
      end
    end

    context "when payment_day is invalid" do
      context "when payment_day is 29" do
        before do
          @init_count = CreditRelation.count
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_day] = 29
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it_should_behave_like "saving invalid param", :payment_day
      end
    end

    context "when payment_day is 99(the special value which means the final day of month)" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_day] = 99
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
      end

      describe "returned value" do
        subject { @cr.save }
        it { should be_true }
      end

      describe "count of record" do
        it { expect { @cr.save! }.to change{ CreditRelation.count }.by(1) }
      end
    end
  end
end
