# -*- coding: utf-8 -*-
class BalanceSheetsController < ApplicationController
  before_filter :required_login
  before_filter :set_separated_accounts, :only => [:show]
  
  #
  # balance sheet
  #
  def index
    mpls = @user.monthly_profit_losses.where("month <= ?", displaying_month)

    @bs = { }
    @bs.default = 0
    mpls.each do |mpl|
      @bs[mpl.account_id] += mpl.amount
    end

    @accounts = @user.accounts.order("order_no").where(:account_type => 'account')
    @bs_plus = { }
    @bs_minus = { }

    @plus = []
    @minus = []
    @total_plus = 0
    @total_minus = 0
    @accounts.each do |a|
      if @bs[a.id] < 0
        @minus.push [a, @bs[a.id]]
        @total_minus += @bs[a.id]
      else
        @plus.push [a, @bs[a.id]]
        @total_plus += @bs[a.id]
      end
    end

    render :layout => 'entries'
  rescue ArgumentError => ex # 日付変換等のエラーがあるため
    redirect_to current_entries_path
  end
  
  def show
    if params[:id].blank?
      redirect_js_to login_url
      return
    else
      @account_id = params[:id].to_i
      from_date = displaying_month
      to_date = displaying_month.end_of_month
      
      @remain_amount, @items = Item.collect_account_history(@user, @account_id, from_date, to_date)
    end
  end
end
