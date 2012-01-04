# -*- coding: utf-8 -*-
require 'test_helper'

class TagStatusesControllerTest < ActionController::TestCase
  fixtures :all
  def test_show_no_login
    xhr :get, :show
    assert_rjs :redirect_to, login_path
  end
  
  def test_show
    login
    # テストデータ
    create_entry  :action_year=>2008, :action_month=>2, :action_day=>3,  :item_name=>'テスト1' , :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :tag_list => 'abc def', :year => 2008, :month => 2
    xhr :get, :show
    assert (not assigns(:tags).empty?)
    assert_equal 2, assigns(:tags).size
    assert_rjs :replace_html, :tag_status
    assert_rjs :visual_effect, :slide_down, :tag_status_body, :duration => '0.2'
    assert_template '_show'
  end

  def test_destroy_no_login
    xhr :delete, :destroy
    assert_rjs :redirect_to, login_path
  end

  def test_destroy
    login
    xhr :delete, :destroy
    assert_rjs :visual_effect, :slide_up, :tag_status_body, :duration => '0.2'
    assert_rjs :replace_html, :tag_status
    assert_template '_show_blank'
  end
end
