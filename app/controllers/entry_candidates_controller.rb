# -*- coding: utf-8 -*-
class EntryCandidatesController < ApplicationController
  before_filter :required_login
  before_filter :set_categorized_accounts, :only => [:index]
  
  #
  # 入力候補の一覧を取得
  #
  def index
    partial_name = params[:item_name]

    if partial_name.blank?
      render :text => ''
      return
    end

    items_table = @user.items.arel_table
    items = @user.items.
      where(items_table[:name].matches("%#{partial_name}%")).
      where(:adjustment => false, :parent_id => nil).
      group('name, from_account_id, to_account_id, amount').
      select('distinct max(id) as max_id, name, from_account_id, to_account_id, amount').
      order("max_id desc").limit(5)
    render :partial => 'candidate', :collection => items
  end
end
