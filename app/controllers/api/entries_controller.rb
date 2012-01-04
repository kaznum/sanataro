class Api::EntriesController < ApplicationController
  before_filter :required_login
  before_filter :valid_combined_month?
  respond_to :json

  def index
    date = Date.new(@year, @month)
    
    items = @user.items.where(:action_date => date.beginning_of_month..date.end_of_month).order("action_date desc, id desc")
    respond_with items.to_custom_hash.to_json
  end

  def show
    
  end

  def destroy
  end

  def update
    
  end

  private
  def valid_combined_month?
    if CommonUtil.valid_combined_year_month?(params[:year_month])
      @year, @month = CommonUtil.get_year_month_from_combined(params[:year_month])
    else
      redirect_to login_url
    end
  end
end
