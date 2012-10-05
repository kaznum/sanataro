# -*- coding: utf-8 -*-
class Api::YearlyBudgetsController < ApplicationController
  include Api
  respond_to :json

  before_filter :_redirect_if_invalid_budget_type!

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    date_since = Date.new(year.to_i, month.to_i).months_ago(11)

    budget_type = params[:budget_type]
    budget_type = Account.account_type_to_type(budget_type)
    results = ['Expense', 'Income'].include?(budget_type) ? _formatted_income_or_outgo_data(budget_type, date_since) : _formatted_total_data(date_since)

    respond_with results
  end

  private
  def _redirect_if_invalid_budget_type!
    if ['outgo', 'income', 'total'].include?(params[:budget_type])
      true
    else
      render status: :not_acceptable, text: "Not Acceptable"
      false
    end
  end

  def _formatted_income_or_outgo_data(budget_type, date_since)
    accounts = @user.accounts.where(type: budget_type).order("order_no").all
    accounts << Account.new {|a|
      a.id = -1
      a.name = 'Unknown'
    }

    results = accounts.inject({}) { |ret, acc|
      amounts = (0..11).map { |i|
        month = date_since.months_since(i)
        amount = _monthly_amount_per_account(month, budget_type, acc.id)
        [month.to_milliseconds, amount.abs]
      }
      ret["account_#{acc.id}"] = { :label => acc.name, :data  => amounts }
      ret
    }
    results
  end

  def _monthly_amount_per_account(month, budget_type, account_id)
    mpl = @user.monthly_profit_losses.where(month: month, account_id: account_id).first
    amount = mpl ? mpl.amount : 0
    if account_id == -1
      if budget_type == 'Income'
        amount = amount < 0 ? amount : 0
      elsif budget_type == 'Expense'
        amount = amount > 0 ? amount : 0
      end
    end
    amount
  end

  def _formatted_total_data(date_since)
    results = _monthly_totals_during_a_year(date_since)

    { outgo: { label: I18n.t('label.outgoing'),
        data: results[:outgos].map{|a| [a[0].to_milliseconds, a[1]]} },
      income: { label: I18n.t('label.income'),
        data: results[:incomes].map{|a| [a[0].to_milliseconds, a[1]]} },
      total: { label: I18n.t('label.net'),
        data: results[:totals].map{|a| [a[0].to_milliseconds, a[1]]} }}
  end

  def _monthly_totals_during_a_year(date_since)
    expense_ids = @user.expense_ids
    income_ids = @user.income_ids

    (0..11).inject({incomes: [], outgos: [], totals: []}) { |ret, i|
      month = date_since.months_since(i)
      totals = _monthly_total(month, expense_ids, income_ids)
      ret[:incomes] << [month, totals[:income].abs]
      ret[:outgos] << [month, totals[:outgo].abs]

      # don't use int.abs because total_amount could be minus.
      ret[:totals] << [month, (-1) * totals[:total]]
      ret
    }
  end

  def _monthly_total(month, expense_ids, income_ids)
    monthly_pl_scope = @user.monthly_profit_losses.where(month: month)
    outgo_amount = monthly_pl_scope.where(account_id: expense_ids).sum(:amount)
    income_amount = monthly_pl_scope.where(account_id: income_ids).sum(:amount)
    unknown_amount = monthly_pl_scope.where(account_id: -1).sum(:amount)
    total_amount = outgo_amount + income_amount + unknown_amount

    if unknown_amount < 0
      income_amount += unknown_amount
    else
      outgo_amount += unknown_amount
    end
    { income: income_amount, outgo: outgo_amount, total: total_amount }
  end
end
