# -*- coding: utf-8 -*-
require 'test_helper'

class Settings::AccountsControllerTest < ActionController::TestCase
  fixtures :all

  def test_index_not_login
    get :index, :account_type => nil
    assert_redirected_to login_path #:controller => :login, :action => :login
  end

#  def test_index_no_get
#    login
#    xhr :get, :index, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10' 
#    assert_rjs :redirect_to, login_path
#  end
  
  def test_index_invalid_type
    login

    get :index, :account_type => 'hogehoge'
    assert_response :redirect
    assert_redirected_to login_path # :controller => :login, :action => :login
    assert_nil assigns(:accounts)
  end
  
  def test_index
    login
    
    get :index, :account_type => nil
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:accounts)
    assert_equal 'account', assigns(:account_type)
    assigns(:accounts).each do |a|
      assert_equal 'account', a.account_type
    end

    get :index, :account_type => 'account'
    assert_response :success
    assert_not_nil assigns(:accounts)
    assert_equal 'account', assigns(:account_type)
    assigns(:accounts).each do |a|
      assert_equal 'account', a.account_type
    end

    get :index, :account_type => 'outgo'
    assert_response :success
    assert_not_nil assigns(:accounts)
    assert_equal 'outgo', assigns(:account_type)
    assigns(:accounts).each do |a|
      assert_equal 'outgo', a.account_type
    end

    get :index, :account_type => 'income'
    assert_response :success
    assert_not_nil assigns(:accounts)
    assert_equal 'income', assigns(:account_type)
    assigns(:accounts).each do |a|
      assert_equal 'income', a.account_type
    end

  end
  
  def test_create_no_login
    xhr :post, :create, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10' 
    assert_rjs :redirect_to, login_path # :controller => :login, :action => :login
  end
  
  def test_create_no_xhr
    login
    post :create, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10' 
    assert_redirected_to login_path # :controller => :login, :action => :login
  end
  
  def test_create
    login
    xhr :post, :create, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10' 
    assert_rjs :redirect_to, settings_accounts_path(:account_type => 'account')
    before_separated_accounts = User.find(session[:user_id]).get_separated_accounts
    # 正常処理
    before_count = Account.count
    before_bgcolors_count = before_separated_accounts[:account_bgcolors].size
    
    xhr :post, :create, :account_name => 'hogehoge', :order_no => '100', :account_type => 'account'
    after_count = Account.count
    assert_no_rjs :redirect_to, login_path
    assert_rjs :redirect_to, settings_accounts_path(:account_type => 'account')
    assert_equal before_count + 1, after_count
    assert_equal before_bgcolors_count, before_separated_accounts[:account_bgcolors].size
    
    # account_typeが不正
    before_count = Account.count
    xhr :post, :create, :account_name => 'hogehoge', :order_no => '100', :account_type => 'acco'
    after_count = Account.count
    assert_no_rjs :redirect_to, login_path
    assert_no_rjs :redirect_to, :action => :accounts
    assert_rjs :replace_html, :add_warning
    assert_equal before_count, after_count
  end
  
  def test_destroy_no_login
    dummy = _create_dummy_record

    xhr :delete, :destroy, :id => dummy.id
    assert_rjs :redirect_to, login_path
  end
  def test_destroy_invalid_get_method
    dummy = _create_dummy_record

    login

    get :destroy, :id => dummy.id
    assert_redirected_to login_path
  end
  def test_destroy_invalid_post_method

    dummy = _create_dummy_record
    login
    post :destroy, :id => dummy.id
    assert_redirected_to login_path # :controller => :login, :action => :login
    separated_accounts = User.find(session[:user_id]).get_separated_accounts
  end
  
  def  test_destroy
    dummy = _create_dummy_record
    login
    before_count = Account.count
    xhr :delete, :destroy, :id => dummy.id
    after_count = Account.count
    assert_rjs :remove, 'account_' + dummy.id.to_s
    assert_equal before_count - 1, after_count
  end
  
  def test_destroy_when_already_used
    dummy = _create_dummy_record
    login
    before_count = Account.count

    before_count = Account.count
    xhr :delete, :destroy, :id => accounts(:bank1).id
    after_count = Account.count
    assert_rjs :replace_html, :add_warning
    assert_no_rjs :replace, 'account_' + accounts(:bank1).id.to_s
    assert_equal before_count, after_count
  end
  def _create_dummy_record
    dummy = Account.new
    dummy.name = 'hogehoge'
    dummy.account_type = 'account'
    dummy.order_no = 100
    dummy.user_id = users(:user1).id
    dummy.save!
    return dummy
  end
  
  def test_edit_no_login
    xhr :get, :edit, :id => accounts(:bank1).id
    assert_rjs :redirect_to, login_path
  end

  def test_edit_invalid_method
    login
    get :edit, :id => accounts(:bank1).id
    assert_redirected_to login_path
    
    post :edit, :id => accounts(:bank1).id
    assert_redirected_to login_path
  end

  def test_edit
    login
    xhr :get, :edit, :id => accounts(:bank1).id
    assert_not_nil assigns(:account)
    assert_rjs :replace, 'account_' + accounts(:bank1).id.to_s

  end    
  
  def test_update_no_login
    xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '10', :bgcolor => '222222'
    assert_rjs :redirect_to, login_path
  end
  
  def test_update_invalid_method
    put :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '10', :bgcolor => '222222'
    assert_redirected_to login_path
  end
  
  def test_update
    login
    xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '100', :bgcolor => "cccccc", :use_bgcolor => '1'
    assert_rjs :redirect_to, settings_accounts_path(:account_type => accounts(:bank1).account_type )
    separated_accounts = User.find(session[:user_id]).get_separated_accounts
    new_acct = Account.find(accounts(:bank1).id)
    assert_equal 'hogehoge', new_acct.name
    assert_equal 100, new_acct.order_no
    assert_equal 'account', new_acct.account_type
    assert_equal 'hogehoge', separated_accounts[:all_accounts][accounts(:bank1).id]
    assert_equal 'cccccc' , new_acct.bgcolor
    assert_equal 'cccccc', separated_accounts[:account_bgcolors][accounts(:bank1).id]
  end
  def test_update_name_is_empty
    new_acct = Account.find(accounts(:bank1).id)
    login
    
    # 名前が空白
    xhr :put, :update, :id => accounts(:bank1).id, :account_name => nil, :order_no => '100', :bgcolor => 'dddddd', :use_bgcolor => '1'
    assert_rjs :replace_html, 'account_' + accounts(:bank1).id.to_s + '_warning'
    new2_acct = Account.find(accounts(:bank1).id)
    
    assert_equal new_acct.name, new2_acct.name
    assert_equal new_acct.order_no, new2_acct.order_no
    assert_equal new_acct.account_type, new2_acct.account_type
    assert_equal new_acct.bgcolor, new2_acct.bgcolor
  end
  def test_update_use_bgcolor_is_nil
    login
    # use_bgcolorがnil
    xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '100', :bgcolor => "cccccc"
    assert_rjs :redirect_to, settings_accounts_path(:account_type => accounts(:bank1).account_type)

    new_acct = Account.find(accounts(:bank1).id)
    assert_equal 'hogehoge', new_acct.name
    assert_equal 100, new_acct.order_no
    assert_equal 'account', new_acct.account_type
    assert_nil new_acct.bgcolor
  end
  
  def test_show_no_login
    xhr :get, :show, :id => accounts(:bank1).id
    assert_rjs :redirect_to, login_path
  end
  
  def test_show_invalid_method
    get :show, :id => accounts(:bank1).id
    assert_redirected_to login_path
  end
  
  def test_show
    login
    # 正常処理
    xhr :get, :show, :id => accounts(:bank1).id
    assert_rjs :replace, 'account_' + accounts(:bank1).id.to_s
    assert_no_rjs :redirect_to, login_path #:controller => :login, :action => :login
    assert_not_nil assigns(:account)

    # IDが無い
    xhr :get, :show, :id => nil
    assert_rjs :redirect_to, login_path #:controller => :login, :action => :login
  end
end
