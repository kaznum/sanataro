# -*- coding: utf-8 -*-
#require File.dirname(__FILE__) + '/../test_helper'
require 'test_helper'

class AccountTest <  ActiveSupport::TestCase
	fixtures :accounts, :items, :monthly_profit_losses, :users

	def test_create
		acc = Account.new
		acc.user_id = 1
		acc.name = 'aaaaa'
		acc.account_type = 'account'
		acc.order_no = 1
		assert acc.save
		assert_not_nil acc.updated_at
		assert_equal true, acc.is_active?
	end
	

	def test_create_name_nil
		acc = Account.new
		acc.user_id = 1
		acc.name = nil
		acc.account_type = 'account'
		acc.order_no = 1
		assert (not acc.save)
	end


	def test_create_name_blank
		acc = Account.new
		acc.user_id = 1
		acc.name = ''
		acc.account_type = 'account'
		acc.order_no = 1
		assert (not acc.save)
	end

	def test_create_name_too_long
		acc = Account.new
		acc.user_id = 1
		acc.name = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456'
		acc.account_type = 'account'
		acc.order_no = 1
		assert (not acc.save)
	end

	def test_create_account_type_wrong
		acc = Account.new
		acc.user_id = 1
		acc.name = 'aaaaa'
		acc.account_type = 'accoun'
		acc.order_no = 1
		assert (not acc.save)
	end

	def test_create_account_w_bgcolor
		acc = Account.new
		acc.user_id = 1
		acc.name = 'aaaaa'
		acc.account_type = 'account'
		acc.order_no = 1
    acc.bgcolor = 'ff0f1f'
		assert acc.save
	end

	def test_create_account_w_bgcolor_error
		acc = Account.new
		acc.user_id = 1
		acc.name = 'aaaaa'
		acc.account_type = 'account'
		acc.order_no = 1
    acc.bgcolor = 'f0f2fg'
		assert (not acc.save)
	end

	def test_create_order_nil
		acc = Account.new
		acc.user_id = 1
		acc.name = 'aaaaa'
		acc.account_type = 'account'
		acc.order_no = nil
		assert (not acc.save)
	end


	#
	# 現在の口座残高を取得
	#
	def test_asset

		# adjustment_idを指定しない
		ini_bank1 = accounts(:bank1)
		date = items(:item5).action_date
		user = users(:user1)
		total = user.accounts.asset(user, ini_bank1.id, date)
		assert_equal 13900, total

		# adj_id を指定(日時はadj_idと同じ)
		ini_bank1 = accounts(:bank1)
		date = items(:adjustment4).action_date.clone
		total = user.accounts.asset(user, ini_bank1.id, date, items(:adjustment4).id)
		assert_equal 15000, total

		# bank1がfrom_account_idのitemのid を指定(日時はadjustment4の日時 + 1day)
		ini_bank1 = accounts(:bank1)
		date = items(:adjustment4).action_date.clone + 1
		total = user.accounts.asset(user, ini_bank1.id, date, items(:item3).id)
		assert_equal 19000, total


		# adj_id を指定(日時はadj_idよりも未来にする)
		ini_bank1 = accounts(:bank1)
		date = items(:adjustment6).action_date + 1
		total = user.accounts.asset(user, ini_bank1.id, date, items(:adjustment4).id)
		assert_equal 13900, total
	end

	
	def test_account_status
#		user1 = users(:user1)
		
#		values = Account.account_status(user1)
		
	end

end
