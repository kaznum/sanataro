# -*- coding: utf-8 -*-
require 'test_helper'

class ConfirmationRequiredsControllerTest < ActionController::TestCase
  fixtures :items, :accounts
  
  test "ログインしていない場合、ログイン画面にリダイレクトすること" do
    xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true'
    assert_rjs :redirect_to, login_path
  end

  test "状態をfalseからtrueに変更できること" do
    login
    assert !items(:item3).confirmation_required?
    xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true'
    new_item = Item.find(items(:item3).id)
    assert new_item.confirmation_required?
    assert_rjs :replace, "item_#{items(:item3).id}"
  end
  
  test "状態をtrueからfalseに変更できること" do
    login
    assert items(:item1).confirmation_required?
    xhr :put, :update, :entry_id => items(:item1).id, :confirmation_required => false
    new_item = Item.find(items(:item1).id)
    assert !new_item.confirmation_required?
    assert_rjs :replace, "item_#{items(:item1).id}"
  end

  test "parent_idが存在する場合、parent_idのentryを変更すること" do
    login
    old_credit_payment = items(:credit_payment21)
    old_credit_refill = items(:credit_refill31)

    assert !old_credit_payment.confirmation_required?
    assert !old_credit_refill.confirmation_required?
    
    xhr :put, :update, :entry_id => old_credit_refill.id, :confirmation_required => 'true'
    
    new_credit_payment = Item.find(items(:credit_payment21).id)
    new_credit_refill = Item.find(items(:credit_refill31))
    
    assert new_credit_payment.confirmation_required?
    assert !new_credit_refill.confirmation_required?
  end

  test "IDが指定されていない場合は、current_entriesにリダイレクトすること" do
    login
    xhr :put, :update, :confirmation_required => 'false'
    assert_rjs :redirect_to, current_entries_path
  end
  
  test "状態が指定されていない時、current_entriesにリダイレクトすること" do
    login
    xhr :put, :update, :entry_id => items(:item1).id
    assert_rjs :redirect_to, current_entries_path
  end
end
