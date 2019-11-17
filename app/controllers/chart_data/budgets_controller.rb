class ChartData::BudgetsController < ApplicationController
  include ChartData
  respond_to :json

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])

    from_date = Date.new(year.to_i, month.to_i)
    budget_type = params[:budget_type] == 'expense' ? :expenses : :incomes

    accounts = @user.send(budget_type).to_a

    results = []
    accounts.each do |acc|
      mpl = @user.monthly_profit_losses.where(month: from_date, account_id: acc.id).where.not(amount: 0).first
      if mpl
        results << { label: acc.name, data: mpl.amount.abs }
      end
    end

    # unkown income/expense
    unknown_mpl = @user.monthly_profit_losses.where(month: from_date, account_id: -1).where.not(amount: 0).first
    if unknown_mpl
      if budget_type == :incomes && unknown_mpl.amount < 0
        results << { label: t('label.unknown_income'), data: unknown_mpl.amount.abs }
      elsif budget_type == :expenses && unknown_mpl.amount > 0
        results << { label: t('label.unknown_expense'), data: unknown_mpl.amount.abs }
      end
    end
    respond_with results
  end

end
