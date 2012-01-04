# -*- coding: utf-8 -*-
require 'test_helper'

class BalanceSheetsControllerTest < ActionController::TestCase
  fixtures :all

	def test_index_no_login
		get :index
		assert_redirected_to login_path
  end
  
  def test_index_wo_month
		login
    
		get :index
    assert_equal assigns(:this_month), Date.today.beginning_of_month
		assert_not_nil assigns(:bs)
		assert_not_nil assigns(:accounts)
		assert_not_nil assigns(:bs_plus)
		assert_not_nil assigns(:bs_minus)
		assert_not_nil assigns(:plus)
		assert_not_nil assigns(:minus)
		assert_not_nil assigns(:total_plus)
		assert_not_nil assigns(:total_minus)
		assert_response :success
		assert_template 'index'
		assert_valid_markup
  end

  def test_index_wo_month_which_has_minus
		login
    
    MonthlyProfitLoss.create(:user_id => 1, :month => Date.new(2006,12,1), :account_id => 1, :amount => -2000000)
		get :index
    assert_equal assigns(:this_month), Date.today.beginning_of_month
		assert_not_nil assigns(:bs)
		assert_not_nil assigns(:accounts)
		assert_not_nil assigns(:bs_plus)
		assert_not_nil assigns(:bs_minus)
		assert_not_nil assigns(:plus)
		assert_not_nil assigns(:minus)
		assert_not_nil assigns(:total_plus)
		assert_not_nil assigns(:total_minus)
		assert_response :success
		assert_template 'index'
		assert_valid_markup
  end
  

  def test_index_invalid_month
		login
		# 月が不正
		get :index, :year => '2008', :month => '13'
		assert_redirected_to current_entries_path
  end
  
  def test_index
		login
		get :index, :year => '2008', :month => '2'
		assert_not_nil assigns(:this_month)
		assert_not_nil assigns(:bs)
		assert_not_nil assigns(:accounts)
		assert_not_nil assigns(:bs_plus)
		assert_not_nil assigns(:bs_minus)
		assert_not_nil assigns(:plus)
		assert_not_nil assigns(:minus)
		assert_not_nil assigns(:total_plus)
		assert_not_nil assigns(:total_minus)
		assert_response :success
		assert_template 'index'
		assert_valid_markup
	end
  
  
	def test_show_no_login
		xhr :get, :show, :id => accounts(:bank1).id.to_s
		assert_rjs :redirect_to, login_path
  end

	def test_show_wo_id
		login
		# id がない
		xhr :get, :show, :year=>'2008', :month => '2'
		assert_rjs :redirect_to, login_path
  end
  
	def test_show
		login
		xhr :get, :show, :id => accounts(:bank1).id.to_s, :year => '2008', :month => '2'
		assert_not_nil assigns(:remain_amount)
		assert_not_nil assigns(:items)
		assert_not_nil assigns(:account_id)
    assert_equal accounts(:bank1).id, assigns(:account_id)
    assert_equal accounts(:bank1).id.class, assigns(:account_id).class
		assert_equal 8000,assigns(:remain_amount)
		assigns(:items).each do |item|
			assert item.from_account_id == accounts(:bank1).id ||
        item.to_account_id == accounts(:bank1).id
			assert item.action_date >= Date.new(2008,2) &&
        item.action_date <= Date.new(2008,2).end_of_month
		end
		assert_rjs :replace, :account_history
		assert_template '_show'
		assert_rjs :hide, "account_history_#{assigns(:account_id)}"
		assert_rjs :visual_effect, :appear, "account_history_#{assigns(:account_id)}", :duration => '0.3'
	end
  
	def test_show_wo_date
		login
		xhr :get, :show, :id => accounts(:bank1).id.to_s
		assert_not_nil assigns(:remain_amount)
		assert_not_nil assigns(:items)
		assert_not_nil assigns(:account_id)
    assert_equal accounts(:bank1).id, assigns(:account_id)
    assert_equal accounts(:bank1).id.class, assigns(:account_id).class
		assigns(:items).each do |item|
			assert item.from_account_id == accounts(:bank1).id ||
        item.to_account_id == accounts(:bank1).id
			assert item.action_date >= Date.today.beginning_of_month &&
        item.action_date <= Date.today.end_of_month
		end
		assert_rjs :replace, :account_history
		assert_template '_show'
		assert_rjs :hide, "account_history_#{assigns(:account_id)}"
		assert_rjs :visual_effect, :appear, "account_history_#{assigns(:account_id)}", :duration => '0.3'
	end
  
end
