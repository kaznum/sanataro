require 'spec_helper'

describe ApplicationHelper do
  describe "colored_account_name" do
    before do
      assign(:separated_accounts, { :account_bgcolors => { 1 => "123456" }, :all_accounts => { 1 => "<SAMPLE", 2 => "NOT COLORED>" } })
    end
    describe "colored" do 
      subject { helper.colored_account_name(1) }
      it { should be == "<span style='background-color: #123456; padding-right:2px;padding-left:2px;'>&lt;SAMPLE</span>".html_safe }
    end
    describe "not colored" do 
      subject { helper.colored_account_name(2) }
      it { should be == "NOT COLORED&gt;".html_safe }
    end
  end

  describe "calendar_from" do
    fixtures :users, :monthly_profit_losses
    context "there is monthly_profit_losses records" do 
      before do
        @min_month = MonthlyProfitLoss.where(:user_id => users(:user1).id).minimum(:month)
      end

      subject { helper.calendar_from(users(:user1)) }
      it { should be == @min_month.beginning_of_month.months_ago(2).beginning_of_month }
    end
    
    context "there is no monthly_profit_losses record" do 
      before do
        MonthlyProfitLoss.destroy_all
      end
      
      subject { helper.calendar_from(users(:user1)) }
      it { should be == Date.today.beginning_of_month.months_ago(2).beginning_of_month }
    end
  end

  describe "calendar_to" do
    fixtures :users, :monthly_profit_losses
    context "there is monthly_profit_losses records" do 
      before do
        @max_month = MonthlyProfitLoss.where(:user_id => users(:user1).id).maximum(:month)
      end

      subject { helper.calendar_to(users(:user1)) }
      it { should be == @max_month.beginning_of_month.months_since(2).beginning_of_month }
    end
    
    context "there is no monthly_profit_losses record" do 
      before do
        MonthlyProfitLoss.destroy_all
      end
      
      subject { helper.calendar_to(users(:user1)) }
      it { should be == Date.today.beginning_of_month.months_since(2).beginning_of_month }
    end
  end
end
