# -*- coding: utf-8 -*-
require 'test_helper'

class CreditRelationTest < ActiveSupport::TestCase
  fixtures :credit_relations, :accounts, :users

  # Replace this with your real tests.
  def test_create

	  init_count = CreditRelation.count

	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank1).id
	  cr.settlement_day = 25
	  cr.payment_month = 2
	  cr.payment_day = 10

	  assert cr.save

	  new_count = CreditRelation.count

	  assert_equal init_count + 1, new_count

	  new_cr = CreditRelation.find(cr.id)

	  assert_equal accounts(:bank21).id, new_cr.credit_account_id
	  assert_equal accounts(:bank1).id, new_cr.payment_account_id
	  assert_equal 25, new_cr.settlement_day
	  assert_equal 2, new_cr.payment_month
	  assert_equal 10, cr.payment_day

  end
  
  
  def test_create_same_account

	  init_count = CreditRelation.count

	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank21).id
	  cr.settlement_day = 25
	  cr.payment_month = 2
	  cr.payment_day = 10

	  assert (not cr.save)
  end
  
  def test_create_same_month

	  init_count = CreditRelation.count

	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank1).id

	  # payment_dayがsettlement_dayよりも前
    cr.settlement_day = 25
	  cr.payment_month = 0
	  cr.payment_day = 10

	  assert (not cr.save)
    
	  # payment_dayがsettlement_dayよりも後
	  cr.settlement_day = 25
	  cr.payment_month = 0
	  cr.payment_day = 26

	  assert cr.save
  end
  
  

  def test_create_settlement_day
	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank1).id
	  cr.settlement_day = 25
	  cr.payment_month = 2
	  cr.payment_day = 10

	  cr.settlement_day = 0
	  assert (not cr.save)
	  cr.settlement_day = 25

	  cr.settlement_day = 29
	  assert (not cr.save)
	  cr.settlement_day = 25

	  cr.settlement_day = 99
	  assert cr.save
  end


  def test_create_payment_month
	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank1).id
	  cr.settlement_day = 25
	  cr.payment_month = 2
	  cr.payment_day = 10


	  cr.payment_month = -1
	  assert (not cr.save)

	  cr.payment_month = 2
	  assert cr.save
  end

  def test_create_payment_day
	  cr = CreditRelation.new
	  cr.user_id = users(:user1).id
	  cr.credit_account_id = accounts(:bank21).id
	  cr.payment_account_id = accounts(:bank1).id
	  cr.settlement_day = 25
	  cr.payment_month = 2
	  cr.payment_day = 10

	  cr.payment_day = 0
	  assert (not cr.save)
	  
	  cr.payment_day = 29
	  assert (not cr.save)

	  cr.payment_day = 99
	  assert cr.save
  end
  
  
end
