class Admin::UsersController < ApplicationController
  before_filter :authenticate
  def index
    @users = User.all
    render :action => :index, :layout => 'admin'
  end

  private
  def authenticate
    if ENV['ADMIN_USER'].blank? || ENV['ADMIN_PASSWORD'].blank?
      redirect_to login_url
      return false
    end
    
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['ADMIN_USER'] && password == ENV['ADMIN_PASSWORD']
    end
  end    

end
