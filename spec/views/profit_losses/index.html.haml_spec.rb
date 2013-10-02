require 'spec_helper'

class ActionView::Base
  def displaying_month
    Date.today
  end
end

describe "/profit_losses/index" do
  fixtures :users, :accounts, :monthly_profit_losses
  context "when enough params," do
    before do
      assign :user, users(:user1)
      assign :m_pls, { accounts(:income2).id => 100, accounts(:income12).id => 200, accounts(:expense3).id => 300, accounts(:expense13).id => 400 }
      assign :account_incomes, [accounts(:income2), accounts(:income12)]
      assign :total_income, 12_345
      assign :account_expenses, [accounts(:expense3), accounts(:expense13)]
      assign :total_expense, 54_321
    end
    describe "no error" do
      it { expect{ render }.not_to raise_error }
    end

    describe "body" do
      subject { render }
      it { should match /<div[^>]+id='income_chart'/ }
      it { should match /<div[^>]+id='yearly_income_chart'/ }
      it { should match /<div[^>]+id='yearly_income_chart_choices'/ }

      it { should match /<div[^>]+id='expense_chart'/ }
      it { should match /<div[^>]+id='yearly_expense_chart'/ }
      it { should match /<div[^>]+id='yearly_expense_chart_choices'/ }

      it { should match /<div[^>]+id='yearly_total_chart'/ }
      it { should match /<div[^>]+id='yearly_total_chart_choices'/ }
    end
  end
end

