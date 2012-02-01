# -*- coding: utf-8 -*-
class EntryCandidatesController < ApplicationController
  before_filter :required_login
  before_filter :set_categorized_accounts, :only => [:index]
  
  #
  # 入力候補の一覧を取得
  #
  def index
    sub_name = params[:item_name]

    if sub_name.blank?
      render :text=>''
      return
    end

    items = @user.items.
      where("name like ?", '%' + sub_name + '%').where(:is_adjustment => false, :parent_id => nil).select('distinct name, from_account_id, to_account_id, amount').order("id desc").limit(5)
    render :partial => 'candidate', :collection => items
  end
end
