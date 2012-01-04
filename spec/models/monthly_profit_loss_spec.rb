# -*- coding: utf-8 -*-
require 'spec_helper'

describe MonthlyProfitLoss do
	fixtures :monthly_profit_losses, :users, :accounts

  describe "find_by_month" do
    subject { MonthlyProfitLoss.find_all_by_month(Date.new(2008,2)) }
    specify { subject.size.should be > 0 }
	end

  describe "reflect_relatively" do
    
    context "regular status"  do
      before do
        @orig_bank1 = monthly_profit_losses(:bank1200712)
        @orig_outgo3 = monthly_profit_losses(:outgo3200712)
        MonthlyProfitLoss.reflect_relatively(users(:user1), monthly_profit_losses(:bank1200712).month,accounts(:bank1).id, accounts(:outgo3).id, 1234)
      end

      describe "from_account" do
        subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id) }
        its(:amount) { should be @orig_bank1.amount - 1234 }
      end

      describe "to_account" do
        subject { MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200712).id) }
        its(:amount) { should be @orig_outgo3.amount + 1234 }
      end
    end

    context "to_accountのMonthly PLレコードが存在しない場合" do
      before do 
        @orig_bank1 = monthly_profit_losses(:bank1200803)
        orig_outgo3 = MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:outgo3).id, :month => Date.new(2008,3,1)).first
        raise "テストの条件が不正" unless orig_outgo3.nil?
        MonthlyProfitLoss.reflect_relatively(users(:user1), Date.new(2008,3,12), accounts(:bank1).id, accounts(:outgo3).id, 1234)
      end

      describe "from_account" do
        subject { MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:bank1).id, :month => Date.new(2008,3,1)).first}
        its(:amount) { should be @orig_bank1.amount - 1234 }
      end
      
      describe "to_account" do
        subject { MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:outgo3).id, :month => Date.new(2008,3,1)).first}
        its(:amount) { should be 1234 }
      end
    end

    context "from_accountのMonthly PLレコードが存在しない場合" do
      before do 
        @orig_bank1 = monthly_profit_losses(:bank1200803)
        orig_outgo3 = MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:outgo3).id, :month => Date.new(2008,3,1)).first
        raise "テストの条件が不正" unless orig_outgo3.nil?
        MonthlyProfitLoss.reflect_relatively(users(:user1), Date.new(2008,3,12), accounts(:outgo3).id, accounts(:bank1).id, 1234)
      end
      
      describe "from_account" do
        subject { MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:outgo3).id, :month => Date.new(2008,3,1)).first}
        its(:amount) { should be -1234 }
      end

      describe "to_account" do
        subject { MonthlyProfitLoss.where(:user_id => users(:user1).id, :account_id => accounts(:bank1).id, :month => Date.new(2008,3,1)).first}
        its(:amount) { should be @orig_bank1.amount + 1234 }
      end
    end
  end
end  

