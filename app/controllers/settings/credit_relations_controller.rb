# -*- coding: utf-8 -*-
class Settings::CreditRelationsController < ApplicationController
  before_filter :required_login
  before_filter :set_separated_accounts, :only => [:update, :show, :index, :edit, :destroy, :create]
  
  def index
    @credit_relations = @user.credit_relations.all
    render :action=>'index', :layout=>'entries'
  end
  
  def create
    @cr = @user.credit_relations.create(:credit_account_id => params[:credit_account_id].to_i,
                                         :payment_account_id => params[:payment_account_id].to_i,
                                         :settlement_day => params[:settlement_day].to_i,
                                         :payment_month => params[:payment_month].to_i,
                                         :payment_day => params[:payment_day].to_i)

    if @cr.errors.empty?
      @credit_relations = @user.credit_relations.all
      render 'create', handlers: [:rjs]
    else
      render_rjs_error :id => "warning", :errors => @cr.errors, :default_message => 'Error!!'
    end
  end
  
  def destroy
    @user.credit_relations.destroy(params[:id])
    @destroyed_id = params[:id]
    render 'destroy', handlers: [:rjs]
  rescue ActiveRecord::RecordNotFound
    @credit_relations = @user.credit_relations.all
    render "no_record", :handlers => [:rjs]
  end
  
  def edit
    @cr = @user.credit_relations.find(params[:id])
    render 'edit', handlers: [:rjs]
  rescue ActiveRecord::RecordNotFound
    render_rjs_error :id => "warning", :default_errors => "データが存在しません。"
  end
  
  def update
    @cr = @user.credit_relations.find(params[:id])
    @cr.update_attributes!(:credit_account_id => params[:credit_account_id].to_i,
                           :payment_account_id => params[:payment_account_id].to_i,
                           :settlement_day => params[:settlement_day].to_i,
                           :payment_month => params[:payment_month].to_i,
                           :payment_day => params[:payment_day].to_i)
    render 'update', handlers: [:rjs]
  rescue ActiveRecord::RecordNotFound
    @credit_relations = @user.credit_relations.all
    render "no_record", :handlers => [:rjs]
  rescue ActiveRecord::RecordInvalid
    render_rjs_error :id => "edit_warning_#{@cr.id}", :errors => @cr.errors, :default_message => 'Error!!', :before => "Element.update('warning', '');"
  end
  
  def show
    @cr = @user.credit_relations.find(params[:id])
    render "show", :handlers => [:rjs]
  rescue ActiveRecord::RecordNotFound
    redirect_rjs_to settings_credit_relations_url
  end
end
