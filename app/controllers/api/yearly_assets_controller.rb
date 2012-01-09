# coding: utf-8
class Api::YearlyAssetsController < ApplicationController
  respond_to :json

  before_filter :required_login
  before_filter :_redirect_if_invalid_year_month!

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    date_to = Date.new(year.to_i, month.to_i)
    date_since = date_to.months_ago(11)

    accounts = @user.accounts.where(account_type: "account").order(:order_no)
    amounts = {}
    accounts.each do |a|
      amounts["account_#{a.id}"] = []
      (0..11).inject(Account.asset(@user, a.id, date_since.yesterday)) do |amount, i|
        month = date_since.months_since(i)
        mpl = @user.monthly_profit_losses.where(account_id: a.id, month: month).first
        amount += mpl ? mpl.amount : 0
        amounts["account_#{a.id}"] << [month.to_time.to_i * 1000, amount]
        amount
      end
    end

    results = accounts.inject({}) { |data, a|
      data["account_#{a.id}"] = { "label" => a.name, "data" => amounts["account_#{a.id}"] }
      data
    }

    # total
    initial_total = MonthlyProfitLoss.where(account_id: accounts.map{|a| a.id}).where("month < ?", date_since).sum(:amount)
    results["total"] = { "label" => "合計" }
    ignored, results["total"]["data"] = (0..11).inject([initial_total, []]) do |total_data, i|
      month = date_since.months_since(i)
      total_data[0] += MonthlyProfitLoss.where(account_id: accounts.map{|a| a.id}, month: month).sum(:amount)
      total_data[1] << [month.to_time.to_i * 1000, total_data[0]]
      total_data
    end
    
    respond_with results
  end
  
  private
  def _redirect_if_invalid_year_month!
    unless CommonUtil.valid_combined_year_month?(params[:id])
      redirect_to login_url
      return false
    end
    true
  end

end
