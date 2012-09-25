# -*- coding: utf-8 -*-
class EntryCandidatesController < ApplicationController
  before_filter :required_login

  def index
    partial_name = params[:item_name]

    if partial_name.blank?
      render :text => ''
      return
    end

    items_table = @user.items.arel_table

    # In fact order("max_id desc").limit(5) is better, but SQL Server doesn't
    # have limit and Arel generates a special SQL for it but it cannot be 
    # evaluated by SQL server.
    #
    items = @user.items.
      where(items_table[:name].matches("%#{partial_name}%")).
      where(:adjustment => false, :parent_id => nil).
      group('name, from_account_id, to_account_id, amount').
      select('max(id) as max_id, name, from_account_id, to_account_id, amount').order("max_id desc")
    items = ActiveRecord::Base.connection.adapter_name == 'MsSQL' ? items[0..4] : items.limit(5)
    render :partial => 'candidate', :collection => items
  end
end
