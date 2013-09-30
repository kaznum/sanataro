# -*- coding: utf-8 -*-
class Settings::AccountsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :required_login
  before_action :_retrieve_account_or_redirect!, only: [:edit, :update, :destroy, :show]

  def index
    @type = (params[:type].presence || 'banking').to_sym
    unless [:banking, :expense, :income].include?(@type)
      redirect_to login_url
      return
    end

    @accounts = @user.send(@type.to_s.pluralize.to_sym).to_a
    render layout: 'entries'
  end

  def create
    @type = (params[:type].presence || 'banking').to_sym

    @account = @user.send(@type.to_s.pluralize.to_sym).build name: params[:account_name], order_no: params[:order_no]
    @account.save!
    redirect_js_to settings_accounts_url(type: @type)
  rescue ActiveRecord::RecordInvalid
    render_js_error id: "add_warning", errors: @account.errors, default_message: t("error.input_is_invalid")
  end

  def update
    name  = params[:account_name]
    order_no  = params[:order_no]
    bgcolor = params[:use_bgcolor] == '1' ? params[:bgcolor].presence : nil

    @account.update_attributes!(name: name, order_no: order_no, bgcolor: bgcolor)
    redirect_js_to settings_accounts_url(type: @account.type.underscore)
  rescue ActiveRecord::RecordInvalid
    render_js_error id: "account_#{@account.id}_warning", errors: @account.errors, default_message: t('error.input_is_invalid')
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
