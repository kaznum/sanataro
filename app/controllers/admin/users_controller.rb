class Admin::UsersController < ApplicationController
  def index
    @users = User.all
    render :action => :list, :layout => 'admin'
  end
end
