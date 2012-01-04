# -*- coding: utf-8 -*-
class Api::AssetsController < ApplicationController
  before_filter :required_login
  before_filter :valid_combined_month?, :only => :show
  respond_to :json

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    bs = balances_with_account_of_month(year, month)
    
    respond_with params[:asset_type] == 'debt' ? formatted_debts(bs) : formatted_assets(bs)
  end

  private
  def valid_combined_month?
    unless CommonUtil.valid_combined_year_month?(params[:id])
      redirect_to login_url
    end
  end
  
  def balances_with_account_of_month(year, month)
    date = Date.new(year.to_i, month.to_i)
		mpls = @user.monthly_profit_losses.where("month <= ?", date)
    mpls.inject(Hash.new(0)) { |result, mpl| result[mpl.account_id] += mpl.amount; result }
  end

  def formatted_debts(balances_with_accounts)
    formatted_assets_or_debts(balances_with_accounts, :debt)
  end

  def formatted_assets(balances_with_accounts)
    formatted_assets_or_debts(balances_with_accounts, :asset)
  end

  def formatted_assets_or_debts(balances_with_accounts, type=:asset)
		accounts = @user.accounts.where(:account_type => 'account').order("order_no")
    labels_and_data = []
		accounts.each do |a|
      amount = balances_with_accounts[a.id]
      if type == :asset && amount > 0 || type == :debt && amount < 0
        labels_and_data << { :label => a.name, :data => amount.abs }
      end
		end
    labels_and_data
  end
end
