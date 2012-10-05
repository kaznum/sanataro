# -*- coding: utf-8 -*-
class AccountStatusesController < ApplicationController
  before_filter :required_login
  def show
    @account_statuses = _account_status
  end

  private
  def _account_status
    max_date = today
    max_month = max_date.beginning_of_month
    retval = known_account_statuses_between(max_month, max_date)
    unknown_total = unknown_amount_between(max_month, max_date)
    unless unknown_total == 0
      typed_accounts = unknown_total < 0 ? :expenses : :incomes
      unknown_account = @user.send(typed_accounts).build do |a|
        a.name = I18n.t('label.unknown')
        a.order_no = 999999
      end
      retval[unknown_account.account_type] << [unknown_account, unknown_total.abs]
    end

    retval
  end

  def known_account_statuses_between(from, to)
    retval = {'account' => banking_account_statuses_between(from, to),
      'income' => income_account_statuses_between(from, to),
      'outgo' => income_account_statuses_between(from, to) }
  end

  def banking_account_statuses_between(from, to)
    @user.bankings.active.map do |a|
      pl_total = amount_to_last_month(a.id, from)
      from_total = @user.items.where(:from_account_id => a.id).action_date_between(from, to).sum(:amount)
      to_total = @user.items.where(:to_account_id => a.id).action_date_between(from, to).sum(:amount)
      [a, to_total - from_total + pl_total]
    end
  end

  def income_account_statuses_between(from, to)
    @user.incomes.active.map do |a|
      [a, @user.items.where(:from_account_id => a.id).action_date_between(from, to).sum(:amount)]
    end
  end

  def expense_account_statuses_between(from, to)
    @user.incomes.active.map do |a|
      [a, @user.items.where(:to_account_id => a.id).action_date_between(from, to).sum(:amount)]
    end
  end

  def amount_to_last_month(account_id, month)
    @user.monthly_profit_losses.where(account_id: account_id).where("month < ?", month).sum(:amount)
  end

  def unknown_amount_between(from, to)
    @user.items.where(from_account_id: -1).action_date_between(from, to).sum(:amount)
  end
end

