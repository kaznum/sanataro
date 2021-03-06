# frozen_string_literal: true

class ChartData::AssetsController < ApplicationController
  include ChartData
  respond_to :json

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    bs = balances_with_account_of_month(year, month)

    respond_with params[:asset_type] == 'debt' ? formatted_debts(bs) : formatted_assets(bs)
  end

  private

  def balances_with_account_of_month(year, month)
    date = Date.new(year.to_i, month.to_i)
    mpls = @user.monthly_profit_losses.where('month <= ?', date)
    mpls.each_with_object(Hash.new(0)) do |e, a|
      a[e.account_id] += e.amount
    end
  end

  def formatted_debts(balances_with_accounts)
    formatted_assets_or_debts(balances_with_accounts, :debt)
  end

  def formatted_assets(balances_with_accounts)
    formatted_assets_or_debts(balances_with_accounts, :asset)
  end

  def formatted_assets_or_debts(balances_with_accounts, type = :asset)
    accounts = @user.bankings.order('order_no')
    labels_and_data = []
    accounts.each do |a|
      amount = balances_with_accounts[a.id]
      labels_and_data << { label: a.name, data: amount.abs } if type == :asset && amount > 0 || type == :debt && amount < 0
    end
    labels_and_data
  end
end
