class Api::BudgetsController < ApplicationController
  before_filter :required_login
  before_filter :redirect_if_invalid_year_month!
  
  respond_to :json

  def show
    year, month = CommonUtil.get_year_month_from_combined(params[:id])

    from_date = Date.new(year.to_i, month.to_i)
    budget_type = params[:budget_type] == 'outgo' ? "outgo" : "income"
    accounts = @user.accounts.where(:account_type => budget_type).order("order_no").all

    results = []
    accounts.each do |acc|
      mpl = @user.monthly_profit_losses.where(:month => from_date, :account_id => acc.id).where("amount <> 0").first
      if mpl
        results << { :label => acc.name, :data  => mpl.amount.abs }
      end
    end
    
    # unkown income/outgo
    unknown_mpl = @user.monthly_profit_losses.where(:month => from_date, :account_id => -1).where("amount <> 0").first
    if unknown_mpl
      if budget_type == 'income' && unknown_mpl.amount < 0
        results << { :label => t("label.unknown_income"), :data  => unknown_mpl.amount.abs }
      elsif budget_type == 'outgo' && unknown_mpl.amount > 0
        results << { :label => t("label.unknown_outgoing"), :data  => unknown_mpl.amount.abs }
      end
    end
    respond_with results
  end

  private
  def redirect_if_invalid_year_month!
    unless CommonUtil.valid_combined_year_month?(params[:id])
      redirect_to login_url
      return
    end
    return true
  end
end
