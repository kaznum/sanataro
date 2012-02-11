class Admin::UsersController < ApplicationController
  def index
    @users = User.all
    render :action => :index, :layout => 'admin'
  end
end
