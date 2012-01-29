# -*- coding: utf-8 -*-
# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  #For gettext_i18n_rails
  before_filter :set_gettext_locale

  # for i18n
  before_filter :set_locale
  def set_locale
    I18n.locale = params[:locale].presence || :ja
  end

  def default_url_options(options ={})
    {:locale => I18n.locale}
  end

  protect_from_forgery
  #
  # change month to display
  #
  def change_month
    from_year = params[:year].to_i
    from_month = params[:month].to_i
    current_action = params[:current_action]
    _page_redirect_to(from_year, from_month, current_action)
  end

  def set_separated_accounts
    @separated_accounts = @user.get_separated_accounts unless @user.nil?
  end

  private

  def redirect_rjs_to(path)
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
      format.html do
        redirect_to login_url
      end
      format.js do
        redirect_rjs_to login_url
      end
      format.json do
        redirect_to login_url
      end
    end
    return false
  end

  #
  # 日付を指定して一覧を表示
  #
  def _page_redirect_to(from_year, from_month, current_action)
    # 日付が正しいことをチェックする
    Date.new(from_year, from_month)

    respond_to do |format|
      format.html do
        redirect_to url_for(:action => current_action, :year => from_year, :month => from_month)
      end
      format.js do
        redirect_rjs_to url_for(:action => current_action, :year => from_year, :month => from_month)
      end
    end
  rescue
    respond_to do |format|
      format.html do
        redirect_to current_entries_url
      end
      format.js do
        redirect_rjs_to current_entries_url
      end
    end
  end
  
  def render_rjs_error(args)
    @error_js_params = args
    render 'common/error'
  end

  def today
    @application_cached_today ||= Date.today
  end

  def json_date_format(date)
    date.to_time.to_i * 1000
  end
end
