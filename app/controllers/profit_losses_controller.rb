# -*- coding: utf-8 -*-
class ProfitLossesController < ApplicationController
  include MonthlyReports

  def index
    @m_pls = _find_account_id_and_amount_by_month(displaying_month)
    _setup_incomes(@m_pls)
    _setup_expenses(@m_pls)
    _append_unknown_account

    render :layout => 'entries'
  rescue ArgumentError => ex # for error around conversion from string to date
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
    @user.monthly_profit_losses.where(month: month).each {|pl| pls[pl.account_id] = pl.amount}
    pls
  end

  def _setup_incomes(m_pls)
    @account_incomes = @user.incomes.all
    @total_income = @account_incomes.inject(0) {|sum, ai| sum - m_pls[ai.id] }
  end

  def _setup_expenses(m_pls)
    @account_outgos = @user.expenses.all
    @total_outgo = @account_outgos.inject(0) { |sum, og| sum + @m_pls[og.id] }
  end

  def _append_unknown_account
    adjustment_amount = @m_pls[-1]
    unknown_account = Account.new{ |a| a.id = -1 }

    if adjustment_amount < 0
      unknown_account.name = I18n.t("label.unknown_income")
      @account_incomes << unknown_account
      @total_income -= adjustment_amount
    end

    if adjustment_amount > 0
      unknown_account.name = I18n.t("label.unknown_outgoing")
      @account_outgos << unknown_account
      @total_outgo += adjustment_amount
    end
  end
end
