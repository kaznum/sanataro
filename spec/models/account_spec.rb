# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account do
  fixtures :users
  before do
    @valid_params = {
      :name => "aaaaa",
      :account_type => "account",
      :order_no => 1,
    }
  end
  
  context "when create" do
    before  do
      @account = users(:user1).accounts.new(@valid_params)
    end
    
    it "保存できること" do
      @account.save.should be_true
    end

    context "when name is nil" do 
      before do 
        @account.name = nil
        @retval = @account.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end
      
      it "nameのvalidationエラーが存在すること" do 
        @account.should have_at_least(1).errors_on(:name)
      end
    end
    
    context "when name is empty string" do 
      before do
        @account.name = ""
        @retval = @account.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end
      
      it "nameのvalidationエラーが存在すること" do 
        @account.should have_at_least(1).errors_on(:name)
      end
    end

    context "when name length is 255" do 
      before do
        @account.name = "a" * 255
        @retval = @account.save
      end
      
      it "保存できることこと" do
        @retval.should be_true
      end
      
      it "nameのvalidationエラーが存在しないこと" do 
        @account.should have(0).errors_on(:name)
      end
    end

    context "when name length is larger than 255" do 
      before do
        @account.name = "a" * 256
        @retval = @account.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end
      
      it "nameのvalidationエラーが存在すること" do 
        @account.should have_at_least(1).errors_on(:name)
      end
    end

    context "when account type is wrong" do
      before do 
        @acc = Account.new(@valid_params)
        @acc.account_type = 'invalid'
        @retval = @acc.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end

      it "account_typeにvalidation errorが存在すること" do
        @acc.should have_at_least(1).errors_on(:account_type)
      end
    end

    context "when bgcolor is exist," do
      context "and bgcolor does not have #," do
        before do
          @acc = users(:user1).accounts.new(@valid_params)
          @acc.bgcolor = 'ff0f1f'
          @retval = @acc.save
        end
        
        
        it "保存できること" do
          @retval.should be_true
        end
      end

      context "and bgcolor has #," do
        before do
          @acc = users(:user1).accounts.new(@valid_params)
          @acc.bgcolor = '#ff0f1f'
          @retval = @acc.save
        end
        
        it "can save" do
          @retval.should be_true
        end

        it "does not have # in bgcolor" do
          @acc.bgcolor.should == "ff0f1f"
        end
      end
    end
    
    context "when bgcolor is exist but wrong" do
      before do 
        @acc = users(:user1).accounts.new(@valid_params)
        @acc.bgcolor = 'f0f2fg'
        @retval = @acc.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end

      it "bgcolorにvalidation errorが存在すること" do
        @acc.should have_at_least(1).errors_on(:bgcolor)
      end
    end

    context "when order_no is nil" do
      before do 
        @acc = users(:user1).accounts.new(@valid_params)
        @acc.order_no = nil
        @retval = @acc.save
      end
      
      it "保存できないこと" do
        @retval.should be_false
      end

      it "order_noにvalidation errorが存在すること" do
        @acc.should have_at_least(1).errors_on(:order_no)
      end
    end
  end

  context "when getting asset balance" do
    fixtures :accounts, :items, :monthly_profit_losses, :users

    context "when adjustment_id isn't specified" do
      subject {
        ini_bank1 = accounts(:bank1)
        date = items(:item5).action_date
        user = users(:user1)
        user.accounts.asset(user, ini_bank1.id, date)
      }
      it {should be 13900}
    end
    
    context "when adj_id を指定(日時はadj_idと同じ)" do
      subject {
        user = users(:user1)
        ini_bank1 = accounts(:bank1)
        date = items(:adjustment4).action_date.clone
        user.accounts.asset(user, ini_bank1.id, date, items(:adjustment4).id)
      }
      it {should be 15000}
    end

    context "when bank1がfrom_account_idのitemのid を指定(日時はadjustment4の日時 + 1day)" do
      subject {
        user = users(:user1)
        ini_bank1 = accounts(:bank1)
        date = items(:adjustment4).action_date.clone + 1
        user.accounts.asset(user, ini_bank1.id, date, items(:item3).id)
      }
      it { should be 19000 }
    end

    context "when adj_id を指定(日時はadj_idよりも未来にする)" do
      subject {
        user = users(:user1)
        ini_bank1 = accounts(:bank1)
        date = items(:adjustment6).action_date + 1
        total = user.accounts.asset(user, ini_bank1.id, date, items(:adjustment4).id)
      }
      it { should be 13900 }
    end
  end

  describe "#credit_due_date" do
    before do
      @credit_params = {
        name: "credit",
        account_type: "account",
        order_no: 1
      }

      @bank_params = {
        name: "bank",
        account_type: "account",
        order_no: 10,
      }

      @relation_params = {
        settlement_day: 10,
        payment_month: 2,
        payment_day: 4,
      }

      @credit = users(:user1).accounts.create!(@credit_params)
      @bank = users(:user1).accounts.create!(@bank_params)
      @relation = users(:user1).credit_relations.create!(@relation_params.merge(credit_account_id: @credit.id, payment_account_id: @bank.id))
    end

    context "when action_date is before the settlemnt_date," do
      subject { @credit.credit_due_date(Date.new(2011,2, 5)) }
      it { should == Date.new(2011,4,4) }
    end
    
    context "when action_date is after the settlemnt_date," do
      subject { @credit.credit_due_date(Date.new(2011,2, 15)) }
      it { should == Date.new(2011,5,4) }
    end

    context "when payment_day is 99" do
      before do 
        @relation.update_attributes!(@relation_params.merge(credit_account_id: @credit.id, payment_account_id: @bank.id, payment_day: 99))
      end

      context "when the action_date is before the settlement_date 5," do
        subject { @credit.credit_due_date(Date.new(2011,7, 5)) }
        it { should == Date.new(2011,9,30) }
      end
    
      context "when end_of_month is 31," do
        subject { @credit.credit_due_date(Date.new(2011,7, 31)) }
        it { should == Date.new(2011,10,31) }
      end
    
      context "when end_of_month is 28," do
        subject { @credit.credit_due_date(Date.new(2011,2, 28)) }
        it { should == Date.new(2011,5,31) }
      end
    end
  end
end
