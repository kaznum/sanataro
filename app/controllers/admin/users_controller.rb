class Admin::UsersController < ApplicationController
  before_filter :authenticate
  def index
    @users = User.all
    render :action => :index, :layout => 'admin'
  end

  private
  def authenticate
    admin_user, admin_password = get_correct_credential
    if admin_user.nil? || admin_password.nil?
      render :nothing => true, :status => :unauthorized
      return
    end

    authenticate_or_request_with_http_basic do |username, password|
      username == admin_user && password == admin_password
    end
  end

  def get_correct_credential
    admin_user =  ENV['ADMIN_USER'].presence
    admin_password = ENV['ADMIN_PASSWORD'].presence

    begin
      admin_user ||= Settings.admin_user
      admin_password ||= Settings.admin_password
    rescue Settingslogic::MissingSetting
      admin_user = admin_password = nil
    end

    [admin_user, admin_password]
  end
end
