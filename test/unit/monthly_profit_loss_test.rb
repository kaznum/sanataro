# -*- coding: utf-8 -*-
require 'test_helper'

class MonthlyProfitLossTest < ActiveSupport::TestCase
	fixtures :monthly_profit_losses, :users, :accounts

	def test_find_by_month
		mpls = MonthlyProfitLoss.find_all_by_month(Date.new(2008,2))
		assert mpls.size > 0
	end
	
	def test_reflect_relatively
		orig_bank1 = monthly_profit_losses(:bank1200712)
		orig_outgo3 = monthly_profit_losses(:outgo3200712)
		MonthlyProfitLoss.reflect_relatively(users(:user1), monthly_profit_losses(:bank1200712).month,accounts(:bank1).id, accounts(:outgo3).id, 1234)
		new_bank1 =  MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
		new_outgo3 =  MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200712).id)
		
		assert_equal orig_bank1.amount - 1234, new_bank1.amount
		assert_equal orig_outgo3.amount + 1234, new_outgo3.amount
	end

	def test_reflect_relatively_to_not_exist_initially
		orig_bank1 = monthly_profit_losses(:bank1200803)
		#orig_outgo3 = monthly_profit_losses(:outgo3200803)
		orig_outgo3 = MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:outgo3).id,
																   Date.new(2008,3,1)]) # nilのはず

		assert_nil orig_outgo3  # fixtureのチェック

		MonthlyProfitLoss.reflect_relatively(users(:user1), Date.new(2008,3,12), accounts(:bank1).id, accounts(:outgo3).id, 1234)
		new_bank1 =  MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:bank1).id,
																   Date.new(2008,3,1)])
		new_outgo3 =  MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:outgo3).id,
																   Date.new(2008,3,1)])
		
		assert_equal orig_bank1.amount - 1234, new_bank1.amount
		assert_equal 1234, new_outgo3.amount

	end

	# from のmonthly_plが存在しない
	def test_reflect_relatively_from_not_exist_initially
		orig_bank1 = monthly_profit_losses(:bank1200803)
		#orig_outgo3 = monthly_profit_losses(:outgo3200803)
		orig_outgo3 = MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:outgo3).id,
																   Date.new(2008,3,1)]) # nilのはず

		assert_nil orig_outgo3  # fixtureのチェック
		# fromのmonthly_plが存在しない場合
		MonthlyProfitLoss.reflect_relatively(users(:user1), Date.new(2008,3,12), accounts(:outgo3).id, accounts(:bank1).id, 1234)
		new_bank1 =  MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:bank1).id,
																   Date.new(2008,3,1)])
		new_outgo3 =  MonthlyProfitLoss.find(:first, :conditions=>["user_id = ? and account_id = ? and month = ?", 
																   users(:user1).id, 
																   accounts(:outgo3).id,
																   Date.new(2008,3,1)])
		
		assert_equal orig_bank1.amount + 1234, new_bank1.amount
		assert_equal -1234, new_outgo3.amount

	end

end
