# -*- coding: utf-8 -*-
class Settings::AccountsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_filter :required_login
 
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
    @account = Account.new(:name => params[:account_name],
                           :order_no => params[:order_no],
                           :account_type => params[:account_type],
                           :user_id => @user.id)
    @account.save!
    redirect_js_to settings_accounts_url(:account_type => @account.account_type)
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "add_warning", :errors => @account.errors, :default_message => '入力値が不正です'
  end
  
  def edit
    @account = @user.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_js_to login_url
  end

  def update
    id  = params[:id]
    name  = params[:account_name]
    order_no  = params[:order_no]
    bgcolor = params[:use_bgcolor] == '1' ?  params[:bgcolor].presence : nil

    @account = @user.accounts.find(id)
    @account.update_attributes!(:name => name, :order_no => order_no, :bgcolor => bgcolor)
    redirect_js_to settings_accounts_url(:account_type => @account.account_type)

  rescue ActiveRecord::RecordNotFound
    redirect_js_to login_url
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "account_#{@account.id}_warning", :errors => @account.errors, :default_message => '入力値が不正です', :before => "$('#edit_button_#{@account.id}').removeAttr('disabled')"
  end

  def destroy
    id = params[:id]
    account = @user.accounts.find(id)

    item = @user.items.where("from_account_id = ? or to_account_id = ?", id, id).first
    if item
      render_js_error :id => "add_warning", :default_message => "すでに収支情報に使用されているため、削除できません。" + 
        l(item.action_date) + " " + item.name + " " + 
        number_to_currency(item.amount)
      return
    end

    credit_rel = @user.credit_relations.where("credit_account_id = ? or payment_account_id = ?", id, id).first
    if credit_rel
      render_js_error :id => "add_warning", :default_message => "クレジットカード支払い情報に関連づけられているため、削除できません。"
      return
    end
    account.destroy
    @account = account
  rescue ActiveRecord::RecordNotFound
    redirect_js_to login_url
  end
  
  def show
    @account = @user.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_js_to login_url
  end
end
