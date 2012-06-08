# -*- coding: utf-8 -*-
class BalanceSheetsController < ApplicationController
  include MonthlyReports

  def index
    @bs = _snapshot_of_month(displaying_month)

    @accounts = @user.accounts.account.order("order_no")

    @bs_plus = { }
    @bs_minus = { }
    @plus = []
    @minus = []
    @total_plus = @total_minus = 0
    @accounts.each do |a|
      if @bs[a.id] < 0
        @minus << [a, @bs[a.id]]
        @total_minus += @bs[a.id]
      else
        @plus << [a, @bs[a.id]]
        @total_plus += @bs[a.id]
      end
    end

    render :layout => 'entries'
  rescue ArgumentError => ex # for errors around conversion from string to date
    redirect_to current_entries_path
  end

  def show
    @account_id = params[:id].to_i
    from_date = displaying_month
    to_date = displaying_month.end_of_month

    @remain_amount, @items = Item.collect_account_history(@user, @account_id, from_date, to_date)
  end

  private
  def _snapshot_of_month(month)
    mpls = @user.monthly_profit_losses.where("month <= ?", month)
    bs = {}
    bs.default = 0
    mpls.each do |mpl|
      bs[mpl.account_id] += mpl.amount
    end
    bs
  end
end
