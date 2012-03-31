# -*- coding: utf-8 -*-
class AccountStatusesController < ApplicationController
  before_filter :required_login
  def show
    @account_statuses = _account_status
  end
  
  private
  def _account_status
    max_date = today.beginning_of_day
    max_month = max_date.beginning_of_month

    retval = known_account_statuses_between(max_month, max_date)

    unknown_total = unknown_amount_between(max_month, max_date)
    unless unknown_total == 0
      unknown_account = Account.new do |a|
        a.name = I18n.t('label.unknown')
        a.order_no = 999999
        a.account_type = unknown_total < 0 ? 'outgo' : 'income'
      end
      retval[unknown_account.account_type].push [unknown_account, unknown_total.abs]
    end
    
    retval
  end

  def known_account_statuses_between(from, to)
    retval = { 'account' => [], 'income' => [], 'outgo' => [] }
    @user.accounts.active.order(:order_no).each do |a|
      pl_total = a.account_type == 'account' ? amount_to_last_month(a.id, from) : 0
      from_total = ['account', 'income'].include?(a.account_type) ? @user.items.where(:from_account_id => a.id).action_date_between(from, to).sum(:amount) : 0
      to_total = ['account', 'outgo'].include?(a.account_type) ? @user.items.where(:to_account_id => a.id).action_date_between(from, to).sum(:amount) : 0

      case a.account_type
      when 'account'
        retval['account'].push [a, to_total - from_total + pl_total]
      when 'income'
        retval['income'].push [a, from_total]
      when 'outgo'
        retval['outgo'].push [a, to_total]
      end
    end
    retval
  end
  
  def amount_to_last_month(account_id, month)
    @user.monthly_profit_losses.where(account_id: account_id).where("month < ?", month).sum(:amount)
  end

  def unknown_amount_between(from, to)
    @user.items.where(from_account_id: -1).action_date_between(from, to).sum(:amount)
  end
end

