# -*- coding: utf-8 -*-
class ProfitLossesController < ApplicationController
  before_filter :required_login
	#
	# monthly profit-loss report
	#
	def index
		year = (params[:year] || today.year).to_i
		month = (params[:month] || today.month).to_i
    from_date = Date.new(year, month)
    
    @from_date = from_date

		@m_pls = { }
		@m_pls.default = 0
		pls = @user.monthly_profit_losses.find_all_by_month(from_date)
		pls.each do |pl|
			@m_pls[pl.account_id] = pl.amount
		end
		
		# 残高調整金額
		adjustment_amount = @m_pls[-1]
		# summation of income
		@account_incomes = @user.accounts.find_all_by_account_type('income',
																   :order=>"order_no")
		# summation of income
		@total_income = 0
		@account_incomes.each do |ai|
			@total_income -= @m_pls[ai.id]
		end

		if adjustment_amount < 0
			account = Account.new
			account.id = -1
			account.name = "不明収入"
			@account_incomes.push account
			@total_income -= adjustment_amount
		end
		# summation of outgo
		@account_outgos = @user.accounts.find_all_by_account_type('outgo',
															  :order=>"order_no")
		@total_outgo = 0
		@account_outgos.each do |og|
			@total_outgo += @m_pls[og.id]
		end

		if adjustment_amount > 0
			account = Account.new
			account.id = -1
			account.name = "不明支出"
			@account_outgos.push account
			@total_outgo += adjustment_amount
		end
		render :layout => 'entries'

	rescue ArgumentError => ex # 日付変換等のエラーがあるため
		redirect_to current_entries_url
	end

	#
	# Ajaxより口座の履歴を読み込む(account_history)
	#
	def show
		if params[:id].blank?
      redirect_rjs_to login_url
			return
    end
    
    if params[:year].blank? || params[:month].blank?
      from_date = today.beginning_of_month
      to_date = today.end_of_month
    else
      from_date = Date.new(params[:year].to_i, params[:month].to_i)
      to_date = Date.new(params[:year].to_i, params[:month].to_i).end_of_month
    end
    
    @account_id = params[:id].to_i

    @remain_amount, @items = Item.collect_account_history(@user, @account_id, from_date, to_date)
    @separated_accounts = @user.get_separated_accounts
  end
end
