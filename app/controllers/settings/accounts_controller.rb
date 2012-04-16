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

    @accounts = @user.accounts.where(:account_type => @account_type).order(:order_no).all
    render :layout => 'entries'
  end

  def create
    @account = @user.accounts.new(:name => params[:account_name],
                                  :order_no => params[:order_no],
                                  :account_type => params[:account_type])
    @account.save!
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
