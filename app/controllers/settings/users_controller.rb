# -*- coding: utf-8 -*-
class Settings::UsersController < ApplicationController
  before_filter :required_login

  def show
    render :layout => 'entries'
  end
  
  def update
    user_to_change = User.find(@user.id)
    user_to_change.email = params[:email]
    user_to_change.password_plain = params[:password_plain]
    user_to_change.password_confirmation = params[:password_confirmation]

    @user_to_change = user_to_change
    user_to_change.save!
    @user = user_to_change
    session[:user_id] = @user.id
  rescue ActiveRecord::RecordInvalid => ex
    render_rjs_error :id => "warning", :errors => @user_to_change.errors, :default_message => _('Input value is incorrect')
  end
  
end
