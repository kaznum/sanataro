# -*- coding: utf-8 -*-
class ProfitLossesController < ApplicationController
  include MonthlyReports

  def index
    @m_pls = _find_account_id_and_amount_by_month(displaying_month)
    _setup_incomes(@m_pls)
    _setup_expenses(@m_pls)
    _append_unknown_account

    render layout: 'entries'
  rescue ArgumentError # for error around conversion from string to date
    redirect_to current_entries_url
  end

  def show
    from_date = displaying_month
    to_date = from_date.end_of_month

    @account_id = params[:id].to_i
    @remain_amount, @items = Item.collect_account_history(@user, @account_id, from_date, to_date)
  end

  private

  def _find_account_id_and_amount_by_month(month)
    pls = { }
    pls.default = 0
    @user.monthly_profit_losses.where(month: month).each { |pl| pls[pl.account_id] = pl.amount }
    pls
  end

  def _setup_incomes(m_pls)
    @account_incomes = @user.incomes.to_a
    @total_income = @account_incomes.reduce(0) { |a, e| a - m_pls[e.id] }
  end

  def _setup_expenses(m_pls)
    @account_expenses = @user.expenses.to_a
    @total_expense = @account_expenses.reduce(0) { |a, e| a + @m_pls[e.id] }
  end

  def _append_unknown_account
    adjustment_amount = @m_pls[-1]

    if adjustment_amount < 0
      unknown_account = @user.incomes.build { |a| a.id = -1 }
      unknown_account.name = I18n.t('label.unknown_income')
      @account_incomes << unknown_account
      @total_income -= adjustment_amount
    end

    if adjustment_amount > 0
      unknown_account = @user.expenses.build { |a| a.id = -1 }
      unknown_account.name = I18n.t('label.unknown_expense')
      @account_expenses << unknown_account
      @total_expense += adjustment_amount
    end
  end
end
