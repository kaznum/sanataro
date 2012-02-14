# -*- coding: utf-8 -*-
class Settings::UsersController < ApplicationController
  before_filter :required_login

  def show
    render :layout => 'entries'
  end
  
  def update
    @user_to_change = User.find(@user.id)
    @user_to_change.update_attributes!(email: params[:email], password_plain: params[:password_plain],
                                       password_confirmation: params[:password_confirmation])
    session[:user_id] = @user.id
  rescue ActiveRecord::RecordInvalid => ex
    render_js_error :id => "warning", :errors => @user_to_change.errors, :default_message => t('error.input_is_invalid')
  end
  
end
