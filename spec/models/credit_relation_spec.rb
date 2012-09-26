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

      subject { @cr }
      specify { subject.errors.should be_empty }
      specify { CreditRelation.count.should be @init_count + 1 }
      it { should_not be_new_record }

      specify {
        new_cr = CreditRelation.find(@cr.id)
        new_cr.credit_account_id.should be accounts(:bank21).id
        new_cr.payment_account_id.should be accounts(:bank1).id
        new_cr.settlement_day.should be 25
        new_cr.payment_month.should be 2
        new_cr.payment_day.should be 10
      }
    end

    context "when create same account" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_account_id] = @valid_attrs[:credit_account_id]
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      subject { @retval }
      it { should be_false }

      it {
        @cr.errors[:credit_account_id].should_not be_empty
      }
    end

    context "when create same account" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_account_id] = @valid_attrs[:credit_account_id]
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      subject { @retval }

      it { should be_false }

      specify { @cr.errors[:credit_account_id].should_not be_empty }
      specify { CreditRelation.count.should be @init_count }
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

      subject { @retval }

      it { should be_false }
      specify { @cr.errors[:credit_account_id].should_not be_empty }
      specify { CreditRelation.count.should be @init_count }
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

      subject { @retval }

      it { should be_false }
      specify { @cr.errors[:payment_account_id].should_not be_empty }
      specify { CreditRelation.count.should be @init_count }
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

        subject { @retval }
        it { should be_false }

        it {
          @cr.errors[:settlement_day].should_not be_empty
        }
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
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:settlement_day] = 0
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it {
          @retval.should be_false
        }

        it {
          @cr.errors[:settlement_day].should_not be_empty
        }
      end

      context "when settlement_day is greater than 28" do
        before do
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:settlement_day] = 29
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it {
          @retval.should be_false
        }

        it {
          @cr.errors[:settlement_day].should_not be_empty
        }
      end
    end

    context "when payment_month is invalid" do
      context "when payment_month is -1" do
        before do
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_month] = -1
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it {
          @retval.should be_false
        }

        it {
          @cr.errors[:payment_month].should_not be_empty
        }
      end
    end

    context "when payment_day is invalid" do
      context "when payment_day is 29" do
        before do
          @invalid_attrs = @valid_attrs.clone
          @invalid_attrs[:payment_day] = 29
          @cr = users(:user1).credit_relations.new(@invalid_attrs)
          @retval = @cr.save
        end

        it {
          @retval.should be_false
        }

        it {
          @cr.errors[:payment_day].should_not be_empty
        }
      end
    end

    context "when payment_day is 99(the special value which means the final day of month)" do
      before do
        @init_count = CreditRelation.count
        @invalid_attrs = @valid_attrs.clone
        @invalid_attrs[:payment_day] = 99
        @cr = users(:user1).credit_relations.new(@invalid_attrs)
        @retval = @cr.save
      end

      it {
        @retval.should be_true
      }

      it {
        CreditRelation.count.should be @init_count + 1
      }
    end
  end
end
