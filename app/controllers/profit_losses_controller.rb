# -*- coding: utf-8 -*-
class ProfitLossesController < ApplicationController
  before_filter :required_login
  before_filter :redirect_if_id_is_nil!, only: :show
  
  def index
    @m_pls = find_account_id_and_amount_by_month(displaying_month)
    
    adjustment_amount = @m_pls[-1]
    unknown_account = Account.new{ |a| a.id = -1 }
    
    @account_incomes = @user.accounts.where(account_type: 'income').order(:order_no).all
    @total_income = @account_incomes.inject(0) {|sum, ai| sum -= @m_pls[ai.id] }
    if adjustment_amount < 0
      unknown_account.name = "不明収入"
      @account_incomes << unknown_account
      @total_income -= adjustment_amount
    end

    @account_outgos = @user.accounts.where(account_type: 'outgo').order(:order_no).all
    @total_outgo = @account_outgos.inject(0) { |sum, og| sum += @m_pls[og.id] }
    if adjustment_amount > 0
      unknown_account.name = "不明支出"
      @account_outgos << unknown_account
      @total_outgo += adjustment_amount
    end
    
    render :layout => 'entries'

  rescue ArgumentError => ex # 日付変換等のエラーがあるため
    redirect_to current_entries_url
  end

  def show
    from_date = displaying_month
    to_date = from_date.end_of_month

    @account_id = params[:id].to_i
    @remain_amount, @items = Item.collect_account_history(@user, @account_id, from_date, to_date)
    @separated_accounts = @user.get_categorized_accounts
  end

  private
  def redirect_if_id_is_nil!
    if params[:id].blank?
      redirect_js_to login_url
      return
    end
    true
  end
  

  def find_account_id_and_amount_by_month(month)
    pls = { }
    pls.default = 0
    @user.monthly_profit_losses.where(month: month).each do |pl|
      pls[pl.account_id] = pl.amount
    end
    pls
  end
end
