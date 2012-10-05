# -*- coding: utf-8 -*-
class Settings::AccountsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_filter :required_login
  before_filter :_retrieve_account_or_redirect!, only: [:edit, :update, :destroy, :show]

  def index
    @account_type = params[:account_type].presence || 'account'
    unless ['account', 'outgo', 'income'].include?(@account_type)
      redirect_to login_url
      return
    end

    message = Account.account_type_to_type(@account_type).underscore.pluralize.to_sym
    @accounts = @user.send(message).all
    render :layout => 'entries'
  end

  def create
    @account_type = params[:account_type].presence || 'account'
    message = Account.account_type_to_type(@account_type)
    unless message
      @account = @user.accounts.build :name => params[:account_name], :order_no => params[:order_no]
      @account.valid?
      raise ActiveRecord::RecordInvalid, @account
    end
    message = message.underscore.pluralize

    @account = @user.send(message).create! :name => params[:account_name], :order_no => params[:order_no]
    redirect_js_to settings_accounts_url(:account_type => @account.account_type)
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "add_warning", :errors => @account.errors, :default_message => t("error.input_is_invalid")
  end

  def update
    name  = params[:account_name]
    order_no  = params[:order_no]
    bgcolor = params[:use_bgcolor] == '1' ? params[:bgcolor].presence : nil

    @account.update_attributes!(:name => name, :order_no => order_no, :bgcolor => bgcolor)
    redirect_js_to settings_accounts_url(:account_type => @account.account_type)
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "account_#{@account.id}_warning", :errors => @account.errors, :default_message => t('error.input_is_invalid')
  end

  def destroy
    @account.destroy
    unless @account.errors.empty?
      render_js_error id: "add_warning", errors: @account.errors.full_messages
      return
    end
  end

  private
  def _retrieve_account_or_redirect!
    @account = @user.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_js_to login_url
    return
  end
end
