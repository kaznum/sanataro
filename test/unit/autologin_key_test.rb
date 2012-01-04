# -*- coding: utf-8 -*-
require 'test_helper'

class AutologinKeyTest < ActiveSupport::TestCase
  fixtures :autologin_keys, :users

  # Replace this with your real tests.
  def test_create
	  ak = AutologinKey.new
	  ak.user_id = users(:user1).id
	  ak.autologin_key = '12345678'
	  assert ak.save
	  assert_not_nil ak.created_at
	  assert_not_nil ak.updated_at
	  assert_not_nil ak.enc_autologin_key
  end

  def test_create_no_user_id
	  ak = AutologinKey.new
#	  ak.user_id = users(:user1).id
	  ak.autologin_key = '12345678'
	  assert (not ak.save)
  end


  def test_create_no_key
	  ak = AutologinKey.new
	  ak.user_id = users(:user1).id
#	  ak.autologin_key = '12345678'
	  assert (not ak.save)
  end

  def test_update
	  old_ak = autologin_keys(:autologin_key1)
	  new_ak = AutologinKey.find(autologin_keys(:autologin_key1).id)
	  new_ak.autologin_key = '88345687'
	  assert (new_ak.save)
	  assert_not_equal old_ak.enc_autologin_key, new_ak.enc_autologin_key
  end

  def test_update_no_user_id
	  old_ak = autologin_keys(:autologin_key1)
	  new_ak = AutologinKey.find(autologin_keys(:autologin_key1).id)
	  new_ak.user_id = nil
	  assert (not new_ak.save)
  end

  def test_correct
	  ak = AutologinKey.new
	  ak.user_id = users(:user1).id
	  ak.autologin_key = '12345678'
	  assert ak.save
	  assert_not_nil ak.created_at
	  assert_not_nil ak.enc_autologin_key


	  assert_not_nil AutologinKey.matched_key(users(:user1).id, '12345678')
	  assert_nil AutologinKey.matched_key(users(:user1).id, '12367')



	  ak = AutologinKey.new
	  ak.user_id = users(:user1).id
	  ak.autologin_key = '55555555'
	  ak.created_at = Time.now - (50 * 24 * 3600)
	  assert ak.save
	  assert_nil AutologinKey.matched_key(users(:user1).id, '55555555')

  end

  def test_cleanup
	  ak = AutologinKey.new
	  ak.user_id = users(:user1).id
	  ak.autologin_key = '12345678'
	  ak.created_at = Time.now - (50 * 24 * 3600)
	  assert ak.save

	  old_count = AutologinKey.count
	  AutologinKey.cleanup(ak.user_id)
	  assert old_count > AutologinKey.count
  end
end
