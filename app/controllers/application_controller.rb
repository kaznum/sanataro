# -*- coding: utf-8 -*-
# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # for i18n
  before_filter :set_locale

  def set_locale
    I18n.locale = available_locale?(params[:locale]) ? params[:locale] : I18n.default_locale
  end

  def available_locale?(locale)
    # FIX ME
    # Now there is no translation for en.
    locale && I18n.available_locales.include?(locale.to_sym) && locale.to_sym != :en
  end

  def default_url_options(options={})
    { :locale => I18n.locale }
  end
  
  protect_from_forgery
  #
  # change month to display
  #
  def change_month
    url = url_for(:action => params[:current_action], :year => displaying_month.year, :month => displaying_month.month)
    respond_to do |format|
      format.html { redirect_to url }
      format.js { redirect_js_to url }
    end
  rescue
    respond_to do |format|
      format.html { redirect_to current_entries_url }
      format.js { redirect_js_to current_entries_url }
    end
  end

  def set_categorized_accounts
    @separated_accounts = @user.get_categorized_accounts unless @user.nil?
  end

  private

  def redirect_js_to(path)
    @path_to_redirect_to = path
    render "common/redirect"
  end

  #
  # getter logined user information from session
  #
  def required_login
    @user = User.find(session[:user_id])
    return true
  rescue ActiveRecord::RecordNotFound => ex
    respond_to do |format|
      format.html { redirect_to login_url }
      format.js { redirect_js_to login_url }
      format.json { redirect_to login_url }
    end
    return false
  end

  def render_js_error(args)
    @error_js_params = args
    render 'common/error'
  end

  def today
    @application_cached_today ||= Date.today
  end

  def json_date_format(date)
    date.to_time.to_i * 1000
  end

  def displaying_month(year = params[:year], month = params[:month])
    if @cached_displaying_month && year == @cached_year && month == @cached_month
      @cached_displaying_month
    else
      @cached_year = year
      @cached_month = month
      @cached_displaying_month = year.present? && month.present? ? Date.new(year.to_i, month.to_i) : today.beginning_of_month
    end
  end
  helper_method :displaying_month
end
