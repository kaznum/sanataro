class Admin::UsersController < ApplicationController
  before_filter :authenticate
  def index
    @users = User.all
    render :action => :index, :layout => 'admin'
  end

  private
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == 'admin' && password == 'ha-dogei'
    end
  end    

end
