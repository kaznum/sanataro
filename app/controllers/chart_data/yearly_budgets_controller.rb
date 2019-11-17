# -*- coding: utf-8 -*-

class ChartData::YearlyBudgetsController < ApplicationController
  include ChartData
  respond_to :json

  before_action :_redirect_if_invalid_budget_type!

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    date_since = Date.new(year.to_i, month.to_i).months_ago(11)

    budget_type = params[:budget_type]
    results = %w(expense income).include?(budget_type) ? _formatted_income_or_expense_data(budget_type, date_since) : _formatted_total_data(date_since)

    respond_with results
  end

  private

  def _redirect_if_invalid_budget_type!
    if %w(expense income total).include?(params[:budget_type])
      true
    else
      render status: :not_acceptable, text: 'Not Acceptable'
      false
    end
  end

  def _formatted_income_or_expense_data(budget_type, date_since)
    accounts = @user.send(budget_type.pluralize.to_sym).to_a
    accounts << Account.new { |a|
      a.id = -1
      a.name = 'Unknown'
    }

    results = accounts.reduce({}) { |ret, acc|
      amounts = (0..11).map { |i|
        month = date_since.months_since(i)
        amount = _monthly_amount_per_account(month, budget_type, acc.id)
        [month.to_milliseconds, amount.abs]
      }
      ret["account_#{acc.id}"] = { label: acc.name, data: amounts }
      ret
    }
    results
  end

  def _monthly_amount_per_account(month, budget_type, account_id)
    mpl = @user.monthly_profit_losses.where(month: month, account_id: account_id).first
    amount = mpl ? mpl.amount : 0
    if account_id == -1
      if budget_type == 'income'
        amount = amount < 0 ? amount : 0
      elsif budget_type == 'expense'
        amount = amount > 0 ? amount : 0
      end
    end
    amount
  end

  def _formatted_total_data(date_since)
    results = _monthly_totals_during_a_year(date_since)

    { expense: {
        label: I18n.t('label.expense'),
        data: results[:expenses].map { |a| [a[0].to_milliseconds, a[1]] }
      },
      income: {
        label: I18n.t('label.income'),
        data: results[:incomes].map { |a| [a[0].to_milliseconds, a[1]] }
      },
      total: {
        label: I18n.t('label.net'),
        data: results[:totals].map { |a| [a[0].to_milliseconds, a[1]] }
      }
    }
  end

  def _monthly_totals_during_a_year(date_since)
    expense_ids = @user.expense_ids
    income_ids = @user.income_ids

    (0..11).reduce({ incomes: [], expenses: [], totals: [] }) { |ret, i|
      month = date_since.months_since(i)
      totals = _monthly_total(month, expense_ids, income_ids)
      ret[:incomes] << [month, totals[:income].abs]
      ret[:expenses] << [month, totals[:expense].abs]

      # don't use int.abs because total_amount could be minus.
      ret[:totals] << [month, (-1) * totals[:total]]
      ret
    }
  end

  def _monthly_total(month, expense_ids, income_ids)
    monthly_pl_scope = @user.monthly_profit_losses.where(month: month)
    expense_amount = monthly_pl_scope.where(account_id: expense_ids).sum(:amount)
    income_amount = monthly_pl_scope.where(account_id: income_ids).sum(:amount)
    unknown_amount = monthly_pl_scope.where(account_id: -1).sum(:amount)
    total_amount = expense_amount + income_amount + unknown_amount

    if unknown_amount < 0
      income_amount += unknown_amount
    else
      expense_amount += unknown_amount
    end
    { income: income_amount, expense: expense_amount, total: total_amount }
  end
end
