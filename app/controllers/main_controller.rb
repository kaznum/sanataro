# -*- coding: utf-8 -*-
class MainController < ApplicationController
  before_filter :required_login
  before_filter :_redirect_if_id_is_blank!, only: [:show_parent_child_item]

  def show_parent_child_item
    id = params[:id].to_i
    type = params[:type].presence || "parent"

    item = type == "parent" ? @user.items.find_by_id(id).try(:parent_item) : @user.items.find_by_parent_id(id)

    if item
      redirect_js_to entries_url(:year => item.action_date.year, :month => item.action_date.month) + "#item_#{item.id}"
    else
      redirect_js_to login_url
    end
  end

  private
  def _redirect_if_id_is_blank!
    if params[:id].blank?
      redirect_js_to login_url
      return
    end
    true
  end
end
