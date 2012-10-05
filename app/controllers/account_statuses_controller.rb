# -*- coding: utf-8 -*-
class AccountStatusesController < ApplicationController
  before_filter :required_login
  def show
    @account_statuses = _account_status
  end

  private
  def _account_status
    retval = known_account_statuses_on(today)
    unknown_total = unknown_amount_on(today)
    unless unknown_total == 0
      typed_accounts = unknown_total < 0 ? :expenses : :incomes
      unknown_account = @user.send(typed_accounts).build do |a|
        a.name = I18n.t('label.unknown')
        a.order_no = 999999
      end
      retval[typed_accounts] << [unknown_account, unknown_total.abs]
    end

    retval
  end

  def known_account_statuses_on(to)
    retval = {}
    [:bankings, :incomes, :expenses].each do |type|
      retval[type] = send("#{type}_statuses_on", to)
    end
    retval
  end

  def bankings_statuses_on(date)
    @user.bankings.active.map { |a| [a, Account.asset(@user, a.id, date)] }
  end

  def incomes_statuses_on(date)
    @user.incomes.active.map { |a| [a, (-1) * Account.asset_beginning_of_month_to_date(@user, a.id, date)] }
  end

  def expenses_statuses_on(date)
    @user.expenses.active.map{ |a| [a, Account.asset_beginning_of_month_to_date(@user, a.id, date)] }
  end

  def unknown_amount_on(date)
    from = date.beginning_of_month
    to = date
    @user.items.where(from_account_id: -1).action_date_between(from, to).sum(:amount)
  end
end

