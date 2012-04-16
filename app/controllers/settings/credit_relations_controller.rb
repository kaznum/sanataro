# -*- coding: utf-8 -*-
class Settings::CreditRelationsController < ApplicationController
  before_filter :required_login
  before_filter :set_categorized_accounts, :only => [:update, :show, :index, :edit, :destroy, :create]

  def index
    @credit_relations = @user.credit_relations.all
    render :layout=>'entries'
  end

  def create
    @cr = @user.credit_relations.create!(:credit_account_id => params[:credit_account_id],
                                         :payment_account_id => params[:payment_account_id],
                                         :settlement_day => params[:settlement_day],
                                         :payment_month => params[:payment_month],
                                         :payment_day => params[:payment_day])

    @credit_relations = @user.credit_relations.all
  rescue ActiveRecord::RecordInvalid => ex
    render_js_error :id => "warning", :errors => ex.error_messages, :default_message => t('error.input_is_invalid')
  end

  def destroy
    @user.credit_relations.destroy(params[:id])
    @destroyed_id = params[:id]
    render 'destroy'
  rescue ActiveRecord::RecordNotFound
    @credit_relations = @user.credit_relations.all
    render "no_record"
  end

  def edit
    @cr = @user.credit_relations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_js_error :id => "warning", :default_errors => t('error.no_data')
  end

  def update
    @cr = @user.credit_relations.find(params[:id])
    @cr.update_attributes!(:credit_account_id => params[:credit_account_id],
                           :payment_account_id => params[:payment_account_id],
                           :settlement_day => params[:settlement_day],
                           :payment_month => params[:payment_month],
                           :payment_day => params[:payment_day])
  rescue ActiveRecord::RecordNotFound
    @credit_relations = @user.credit_relations.all
    render "no_record"
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "edit_warning_#{@cr.id}", :errors => @cr.errors, :default_message => t('error.input_is_invalid')
  end

  def show
    @cr = @user.credit_relations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_js_to settings_credit_relations_url
  end
end
