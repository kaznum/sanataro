# -*- coding: utf-8 -*-
require 'test_helper'

class LoginControllerTest < ActionController::TestCase
	assert_valid_markup :login

	fixtures :users, :autologin_keys

	#
	# ログイン入力フォーム、自動ログイン
	#
	def test_login
		get :login
		assert_response :success
		assert_template 'login'
		assert_tag :tag=>'input', :attributes=>{ :type=>'text', :name=>'login', :tabindex=>1 }
		assert_tag :tag=>'input', :attributes=>{ :type=>'password', :name=>'password', :tabindex=>2 }
		assert_tag :tag=>'input', :attributes=>{ :type=>'checkbox', :name=>'autologin', :tabindex=>3, :value=>1 , :checked=>false }
		assert_tag :tag=>'input', :attributes=>{ :type=>'checkbox', :name=>'only_add', :value=>1, :checked=>false, :tabindex=>4 }
		assert_tag :tag=>'input', :attributes=>{ :type=>'submit', :id=>'login_button', :tabindex=>5 }
  end
  
  def test_login_w_cookie_autologin
    @request.cookies['user'] = 'user1'
    @request.cookies['autologin'] = '1234567'
		get :login
		assert_redirected_to current_entries_path
	end

	#
	# 自動ログインで、cookieのonly_addがtrueの場合は add_item_only_inputを表示
	#
	def test_login_only_add
		@request.cookies['user'] = 'user1'
		@request.cookies['autologin'] = '1234567'
		@request.cookies['only_add'] = '1'
		get :login
		assert_redirected_to new_current_entry_path(:entry_type => 'simple')
	end
	
	# Replace this with your real tests.
	def test_do_login_invalid_password
		xhr :post, :do_login, :login=>'user1', :password=>'user1', :autologin=>nil, :only_add=>nil
		assert_select_rjs :replace_html, :warning, 'UserID or Password is incorrect.'
		assert_nil @request.session[:user]
    assert_nil @request.session[:user_id]
		assert_nil cookies['user']
		assert_nil cookies['autologin']
		assert_nil cookies['only_add']
  end
  
	def test_do_login
		xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>nil, :only_add=>nil
		assert_select_rjs :redirect, current_entries_path
		assert_nil @request.session[:user]
    assert_equal users(:user1).id, @request.session[:user_id]
		#	  assert_nil User.find(users(:user1).id).autologin_key
		assert_nil cookies['user']
		assert_nil cookies['autologin']
		assert_nil cookies['only_add']
  end

  def test_do_login_autologin
		xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>'1', :only_add=>nil
		assert_equal 'user1', cookies['user']
		assert_not_nil cookies['autologin']
		assert_nil cookies['only_add']
		assert_select_rjs :redirect, current_entries_path
		assert_nil @request.session[:user]
    assert_equal users(:user1).id, @request.session[:user_id]
		#	  assert_not_nil User.find(users(:user1).id).autologin_key
		assert AutologinKey.count(:conditions=>["user_id = ? and created_at > ?", users(:user1).id, DateTime.now - 30]) > 0
  end
  def test_do_login_autologin_and_simple_view
		xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>'1', :only_add=>'1'
		assert_equal 'user1', cookies['user']
		assert_not_nil cookies['autologin']
		assert_equal '1', cookies['only_add']
		assert_select_rjs :redirect, new_current_entry_path(:entry_type => 'simple')
		assert_nil @request.session[:user]
    assert_equal users(:user1).id, @request.session[:user_id]
		#assert_not_nil User.find(users(:user1).id).autologin_key
		assert AutologinKey.count(:conditions=>["user_id = ? and created_at > ?", users(:user1).id, Time.now - 30]) > 0
  end
  
  def test_do_login_invalid_method_post
		post :do_login, :login=>'user1', :password=>'123456', :autologin=>'1', :only_add=>'1'
    assert_nil @request.session[:user_id]
		assert_redirected_to :controller => :login, :action => :login
  end
  def test_do_login_invalid_method_get
    get :do_login, :login=>'user1', :password=>'123456', :autologin=>'1', :only_add=>'1'
    assert_nil @request.session[:user_id]
		assert_redirected_to :controller => :login, :action => :login
	end

	def test_do_login_autologin_cleanup
		old_count = AutologinKey.count
		xhr :post, :do_login, :login=>'user1', :password=>'123456', :autologin=>nil, :only_add=>'1'
		assert old_count > AutologinKey.count

	end

	def test_do_logout
		init_user1 = User.find(users(:user1).id)
		get :do_logout
		assert_nil @request.session[:user]
		assert_nil @request.session[:user_id]
    # 初期状態では autologinkeysテーブルに2つのレコードが存在
		assert_equal 2,  AutologinKey.count 
    
		login
		assert_equal 1,  AutologinKey.count

		get :do_logout
		logouted_user1 = User.find(users(:user1).id)
		assert_nil session[:user]
		assert_nil session[:user_id]
		#	  assert_not_nil init_user1.autologin_key
		#	  assert_nil logouted_user1.autologin_key
		assert_equal 1, AutologinKey.count

		assert_redirected_to :action=>:login
	end


  def test_create_user
	  get :create_user
	  assert_response :success
	  assert_template 'create_user'
	  assert_tag :tag=>'input', :attributes=>{ :type=>'text', :name=>'login' }
	  assert_tag :tag=>'input', :attributes=>{ :type=>'password', :name=>'password_plain' }
	  assert_tag :tag=>'input', :attributes=>{ :type=>'password', :name=>'password_confirmation' }
	  assert_tag :tag=>'input', :attributes=>{ :type=>'text', :name=>'email' }

  end

  def test_do_create_user
	  # regular operation
	  xhr :post, :do_create_user, :login=>'hogehoge', :password_plain=>'hagehage', :password_confirmation=>'hagehage', :email => 'email@example.com'
	  assert_select_rjs :replace_html, :warning, ''
	  assert_select_rjs :replace_html, :inputarea
    max_id = User.maximum(:id)
    u = User.find(max_id)
    assert_not_nil u.confirmation
    assert_equal 15, u.confirmation.size
    assert (not u.is_active)

	  # method incorrect
	  post :do_create_user, :login=>'hogehoge1', :password_plain=>'hagehage', :password_confirmation=>'hagehage', :email => 'email@example.com'
	  assert_redirected_to :controller => :login, :action => :login
	  

	  # password mismatch
	  xhr :post, :do_create_user, :login=>'hogehoge2', :password_plain=>'hagehage', :password_confirmation=>'hhhhhhh', :email => 'email@example.com'
	  assert_select_rjs :replace_html, :warning
	  assert_no_rjs :replace_html, :inputarea

	  # password is empty
	  xhr :post, :do_create_user, :login=>'hogehoge3', :password_plain=>'', :password_confirmation=>'', :email => 'email@example.com'
	  assert_select_rjs :replace_html, :warning
	  assert_no_rjs :replace_html, :inputarea

	  # login is empty
	  xhr :post, :do_create_user, :login=>'', :password_plain=>'hogehoge', :password_confirmation=>'hogehoge', :email => 'email@example.com'
	  assert_select_rjs :replace_html, :warning
	  assert_no_rjs :replace_html, :inputarea

	  # login is occupied
	  xhr :post, :do_create_user, :login=>'user1', :password_plain=>'hogehoge', :password_confirmation=>'hogehoge', :email => 'email@example.com'
	  assert_select_rjs :replace_html, :warning
	  assert_no_rjs :replace_html, :inputarea

	  # email is empty
	  xhr :post, :do_create_user, :login=>'hogehoge4', :password_plain=>'hogehoge', :password_confirmation=>'hogehoge', :email => ''
	  assert_select_rjs :replace_html, :warning
	  assert_no_rjs :replace_html, :inputarea
  end

  
  def test_confirmation
    User.create!(:login => 'test200', :password => '1234567', :password_confirmation => '1234567', :confirmation => '123456789012345', :email => 'test@example.com', :is_active => false)
	  get :confirmation, :login => 'test200', :sid => '123456789012345'
	  assert_response :success
	  assert_template 'confirmation'
    
    u = User.find_by_login('test200')
    assert (not u.nil?)
    assert u.is_active
    user = User.find_by_login('test200')
    assert_not_equal 0, user.accounts.count(:conditions => { :account_type => 'account' })
    assert_not_equal 0, user.accounts.count(:conditions => { :account_type => 'income' })
    assert_not_equal 0, user.accounts.count(:conditions => { :account_type => 'outgo' })
    assert_not_equal 0, user.credit_relations.count
    assert_not_equal 0, user.items.count
    assert_not_equal 0, user.monthly_profit_losses.count
    
  end
  
  def test_confirmation_sid_error
    User.create!(:login => 'test200', :password => '1234567', :password_confirmation => '1234567', :confirmation => '123456789012345', :email => 'test@example.com', :is_active => false)
	  get :confirmation, :login => 'test200', :sid => '1234567890'
	  assert_response :success
	  assert_template 'confirmation_error'
    
    u = User.find_by_login('test200')
    assert (not u.nil?)
    assert (not u.is_active)
    
  end
  
end
