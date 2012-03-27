# -*- coding: utf-8 -*-
class Api::YearlyBudgetsController < ApplicationController
  respond_to :json

  before_filter :required_login
  before_filter :_redirect_if_invalid_year_month!
  before_filter :_redirect_if_invalid_budget_type!

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])
    date_since = Date.new(year.to_i, month.to_i).months_ago(11)

    budget_type = params[:budget_type]
    results = ['outgo', 'income'].include?(budget_type) ? _get_income_or_outgo_data(budget_type, date_since) : _get_total_data(date_since)
    
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

  def _redirect_if_invalid_budget_type!
    if ['outgo', 'income', 'total'].include?(params[:budget_type])
      return true
    else
      redirect_to login_url
      return false
    end
  end
  
  def _get_income_or_outgo_data(budget_type, date_since)
    accounts = @user.accounts.where(account_type: budget_type).order("order_no").all
    # accounts << Account.new(:id => -1, :name => 'Unknown') # doesn't work well.(id is ignored)
    accounts << Account.new {|a|
      a.id = -1
      a.name = 'Unknown'
    }
    
    results = accounts.inject({}) { |ret, acc|
      amounts = (0..11).map { |i|
        mpl = @user.monthly_profit_losses.where(month: date_since.months_since(i), account_id: acc.id).first
        amount = mpl ? mpl.amount : 0
        if acc.id == -1
          if budget_type == 'income'
            amount = amount < 0 ? amount : 0
          elsif budget_type == 'outgo'
            amount = amount > 0 ? amount : 0
          end
        end
        [json_date_format(date_since.months_since(i)), amount.abs]
      }
      ret["account_#{acc.id}"] = { :label => acc.name, :data  => amounts }
      ret
    }
    results
  end

  def _get_total_data(date_since)
    outgo_ids = @user.accounts.outgo.order("order_no").map(&:id)
    income_ids = @user.accounts.income.order("order_no").map(&:id)

    results = (0..11).inject({incomes: [], outgos: [], totals: []}) { |ret, i|
      month = date_since.months_since(i)
      totals = _monthly_total(month, outgo_ids, income_ids)
      json_date = json_date_format(month)
      ret[:incomes] << [json_date, totals[:income].abs]
      ret[:outgos] << [json_date, totals[:outgo].abs]

      # don't use int.abs because total_amount could be minus.
      ret[:totals] << [json_date, (-1) * totals[:total]]
      ret
    }
    
		{ outgo: { label: '支出', data: results[:outgos] },
      income: { label: '収入', data: results[:incomes] },
      total: { label: '収支', data: results[:totals] }}
  end

  def _monthly_total(month, outgo_ids, income_ids)
    monthly_pl_scope = @user.monthly_profit_losses.where(month: month)
    outgo_amount = monthly_pl_scope.where(account_id: outgo_ids).sum(:amount)
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
