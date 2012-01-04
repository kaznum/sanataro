# -*- coding: utf-8 -*-
class MainController < ApplicationController
  before_filter :required_login
  #
  # 設定の読みなおし
  #
  def reload_config
    redirect_to current_entries_url
  end

  #
  # クレジットカード支払い情報の決済時、引き落とし時の情報の相互リンクの遷移
  #
  def show_parent_child_item
    if params[:id].blank?
      redirect_rjs_to login_url
      return
    end

    id = params[:id].to_i
    type = params[:type]
    if type.blank? || type == "parent"
      item = @user.items.find_by_child_id(id)
    else
      item = @user.items.find_by_parent_id(id)
    end

    if item.nil?
      redirect_rjs_to login_url
      return
    end
    redirect_rjs_to entries_url(:year => item.action_date.year, :month => item.action_date.month) + "#item_#{item.id}" 
    return
  end
end
