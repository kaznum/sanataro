# -*- coding: utf-8 -*-
class MainController < ApplicationController
  before_filter :required_login
  before_filter :_redirect_if_id_is_blank!, only: [:show_parent_child_item]

  def show_parent_child_item
    redirect_js_to parent_child_of_item_url(params[:id].to_i, params[:type]) || login_url
  end

  private

  def parent_child_of_item_url(id, type = "parent")
    item = type == "parent" ? @user.items.find_by_id(id).try(:parent_item) : @user.items.find_by_parent_id(id)
    item ? entries_url(year: item.action_date.year, month: item.action_date.month, anchor: "item_#{item.id}") : nil
  end

  def _redirect_if_id_is_blank!
    if params[:id].blank?
      redirect_js_to login_url
      return
    end
    true
  end
end
