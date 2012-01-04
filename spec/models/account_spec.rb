# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account do
  
  before do
    @valid_params = {
      :user_id => 1,
      :name => "aaaaa",
      :account_type => "account",
      :order_no => 1,
    }
  end
  
  context "when create" do
    before  do
      @account = Account.new(@valid_params)
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

    context "when bgcolor is exist" do
      before do 
        @acc = Account.new(@valid_params)
        @acc.bgcolor = 'ff0f1f'
        @retval = @acc.save
      end
      
      it "保存できること" do
        @retval.should be_true
      end
    end
    
    context "when bgcolor is exist but wrong" do
      before do 
        @acc = Account.new(@valid_params)
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
        @acc = Account.new(@valid_params)
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
end
