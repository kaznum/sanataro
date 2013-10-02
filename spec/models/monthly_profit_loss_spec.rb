# -*- coding: utf-8 -*-
require 'spec_helper'

describe MonthlyProfitLoss do
  fixtures :monthly_profit_losses, :users, :accounts

  describe "find_all_by_month" do
    subject { MonthlyProfitLoss.where(month: Date.new(2008, 2)).to_a }
    specify { subject.size.should be > 0 }
  end

  describe "::correct" do
    let(:user) { users(:user1) }
    let(:month) { Date.new(2008, 2) }
    # dummy data

    before do
      @orig_bank1 = monthly_profit_losses(:bank1200802)
      @orig_bank1.update_attributes!(amount: 93_423)
    end

    describe "returned value" do
      subject { MonthlyProfitLoss.correct(user, @orig_bank1.account_id, month).amount }

      it { should == Item.where(to_account_id: @orig_bank1.account_id, action_date: month..month.end_of_month).sum(:amount) - Item.where(from_account_id: @orig_bank1.account_id, action_date: month..month.end_of_month).sum(:amount) }
    end

    describe "stored item" do
      before { MonthlyProfitLoss.correct(user, @orig_bank1.account_id, month) }
      subject { MonthlyProfitLoss.find(@orig_bank1.id).amount }

      it { should == Item.where(to_account_id: @orig_bank1.account_id, action_date: month..month.end_of_month).sum(:amount) - Item.where(from_account_id: @orig_bank1.account_id, action_date: month..month.end_of_month).sum(:amount) }
    end
  end
end
