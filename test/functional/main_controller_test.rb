# -*- coding: utf-8 -*-
require 'test_helper'

class MainControllerTest < ActionController::TestCase
  fixtures :all
  
  def test_reload_config_no_login
    get :reload_config
    assert_redirected_to login_path
  end

  def test_reload_config
    login
    get :reload_config
    assert_redirected_to current_entries_path
  end

  def test_show_parent_child_item_no_login
    # no login
    xhr :get, :show_parent_child_item, :id => 1
    assert_select_rjs :redirect, login_path
  end
  
  def test_show_parent_child_item
    login

    # id がしていされていない
    xhr :get, :show_parent_child_item, :id => nil, :type => 'child'
    assert_select_rjs :redirect, login_path

    # id がじつざいしないあたい
    xhr :get, :show_parent_child_item, :id => 10000, :type => 'child'
    assert_select_rjs :redirect, login_path

    # クレジットカードデータのついか(paydayは2 months later)
    xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action=>'items'

    create_entry :action_year=>'2008', :action_month=>'2', :action_day=>'10', :item_name=>'テスト10show_parent_child', 
    :amount=>'10,000', :from=>accounts(:credit4).id, :to=>accounts(:outgo3).id, :year => 2008, :month => 2

    item = Item.find_by_name('テスト10show_parent_child')
    assert_not_nil item
    xhr :get, :show_parent_child_item, :id => item.id, :type => 'child'
    assert_select_rjs :redirect, entries_path(:year => 2008, :month => 4) + "#item_#{item.child_id}"

    # parentが存在しないのに指定する
    xhr :get, :show_parent_child_item, :id => item.id, :type => 'parent'
    assert_select_rjs :redirect, login_path
  end

  #
  # 月リンク
  #
  def test_change_month_no_login
    xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action=>'index'
    assert_select_rjs :redirect, login_path 
  end
  def test_change_month_invalid_date
    login

    # 日付が不正
    xhr :post, :change_month, :year=>'2008', :month=>'13', :current_action=>'index'
    assert_select_rjs :redirect, current_entries_path
  end
  
  def test_change_month
    login

    # 正常処理
    xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action=>'index'
    assert_select_rjs :redirect, @controller.url_for(:action => 'index', :year => '2008', :month => '2', :only_path => true)
  end
end
