# -*- coding: utf-8 -*-
require 'test_helper'

class Settings::CreditRelationsControllerTest < ActionController::TestCase
  fixtures :all
  def test_index_no_login
    get :index
    assert_redirected_to login_path #:controller => :login, :action => :login
  end
  
  def test_index
    login

    get :index
    assert_response :success
    assert_template 'index'
    assert assigns(:credit_relations)
    assert_tag :tag => "form", :attributes => { :action => settings_credit_relations_path, :method => "post", :id => 'add_form' }
  end
  
  
  def test_create_no_login
    xhr :post, :create, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 99, :payment_month => 1, :payment_day => 4
    assert_rjs :redirect_to, login_path
  end
  
  def test_create_invalid_method
    login
    get :create, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 99, :payment_month => 1, :payment_day => 4
    assert_redirected_to login_path
    post :create, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 99, :payment_month => 1, :payment_day => 4
    assert_redirected_to login_path
  end

  def test_create
    login
    # 正常
    before_count = CreditRelation.count(:conditions => { :user_id => users(:user1).id })
    xhr :post, :create, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 99, :payment_month => 1, :payment_day => 4
    assert_rjs :replace_html, :warning, ''
    assert_rjs :replace_html, :credit_relations, ''
    assert_rjs :insert_html, :bottom, :credit_relations
    assert_equal before_count + 1, CreditRelation.count(:conditions => { :user_id => users(:user1).id })

    # 不正
    before_count = CreditRelation.count(:conditions => { :user_id => users(:user1).id })
    xhr :post, :create, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 99, :payment_month => 1, :payment_day => nil
    assert_rjs :replace_html, :warning
    assert_equal before_count, CreditRelation.count(:conditions => { :user_id => users(:user1).id })
    
  end
  
  def test_destroy_no_login
    cr = CreditRelation.create(:user_id => users(:user1).id, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10)

    xhr :delete, :destroy, :id => cr.id
    assert_rjs :redirect_to, login_path
  end
  
  def test_destroy_invalid_method
    cr = CreditRelation.create(:user_id => users(:user1).id, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10)
    
    login

    get :destroy, :id=>cr.id
    assert_redirected_to login_path
    post :destroy, :id=>cr.id
    assert_redirected_to login_path
  end

  
  def test_destroy
    cr = CreditRelation.create(:user_id => users(:user1).id, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10)
    
    login
    
    # 正常処理
    before_count = CreditRelation.count(:conditions => { :user_id => users(:user1).id })
    xhr :delete, :destroy, :id=>cr.id
    assert_rjs :replace_html, :warning, ''
    assert_rjs :replace_html, 'credit_relation_' + cr.id.to_s, ''
    assert_equal before_count - 1, CreditRelation.count(:conditions => { :user_id => users(:user1).id })

    # IDが存在しない
    before_count = CreditRelation.count(:conditions => { :user_id => users(:user1).id })
    xhr :delete, :destroy, :id=>10000
    assert_rjs :replace_html, :credit_relations, ''
    assert_rjs :insert_html, :bottom, :credit_relations
    assert_equal before_count, CreditRelation.count(:conditions => { :user_id => users(:user1).id })
  end
  
  def test_edit_no_login
    xhr :get, :edit, :id=>credit_relations(:cr1).id
    assert_rjs :redirect_to, login_path
  end
  
  def test_edit_invalid_mothod
    login

    get :edit, :id=>credit_relations(:cr1).id
    assert_redirected_to login_path #:controller => :login, :action => :login

    post :edit, :id=>credit_relations(:cr1).id
    assert_redirected_to login_path #:controller => :login, :action => :login
  end
  
  def test_edit
    login

    # 正常処理
    xhr :get, :edit, :id=>credit_relations(:cr1).id
    assert_rjs :replace_html, 'credit_relation_' + credit_relations(:cr1).id.to_s
    assert_rjs :replace_html, :warning, ''
    assert_not_nil assigns(:cr)


    # idが存在しない
    xhr :get, :edit, :id=>100
    assert_rjs :replace_html, :warning
  end
  
  def test_update_no_login
    xhr :put, :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    assert_rjs :redirect_to, login_path #:controller => :login, :action => :login
  end
  
  def test_update_invalid_method
    login

    get :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    assert_redirected_to login_path #:controller => :login, :action => :login

    post :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    assert_redirected_to login_path #:controller => :login, :action => :login

    put :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    assert_redirected_to login_path #:controller => :login, :action => :login
  end
  
  def test_update
    login

    # 正常処理
    xhr :put, :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    after_cr = CreditRelation.find_by_id(credit_relations(:cr1).id)
    assert_rjs :replace_html, :warning, ''
    assert_rjs :replace_html, 'credit_relation_' + credit_relations(:cr1).id.to_s
    bank21_credit = CreditRelation.find_by_credit_account_id(accounts(:bank21).id)
    assert_not_equal nil, bank21_credit
    assert_equal accounts(:bank1).id, bank21_credit.payment_account_id
    assert_equal 25, bank21_credit.settlement_day
    assert_equal 2, bank21_credit.payment_month
    assert_equal 10, bank21_credit.payment_day
    assert_not_nil assigns(:cr)

    # DBにデータが存在しない
    xhr :put, :update, :id=>1000, :credit_account_id => accounts(:bank21).id, :payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => 10
    assert_rjs :insert_html, :bottom, :credit_relations

    #payment_dayが空白
    xhr :put, :update, :id=>credit_relations(:cr1).id, :credit_account_id => accounts(:bank21).id ,:payment_account_id => accounts(:bank1).id, :settlement_day => 25, :payment_month => 2, :payment_day => nil
    assert_rjs :replace_html, 'edit_warning_' + credit_relations(:cr1).id.to_s
  end
  
  def test_show_no_login
    xhr :get, :show, :id=>credit_relations(:cr1).id
    assert_rjs :redirect_to, login_path #:controller => :login, :action => :login
  end
  
  def test_show_invalid_method
    login

    get :show, :id=>credit_relations(:cr1).id
    assert_redirected_to login_path #:controller => :login, :action => :login
    post :show, :id=>credit_relations(:cr1).id
    assert_redirected_to login_path #:controller => :login, :action => :login

  end
  
  def test_show
    login
    xhr :get, :show, :id=>credit_relations(:cr1).id
    assert_rjs :replace_html, 'credit_relation_' + credit_relations(:cr1).id.to_s
    assert_not_nil assigns(:cr)
  end
  
end
