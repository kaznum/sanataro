require 'test_helper'
require 'digest/sha1'

class UserTest < ActiveSupport::TestCase
	fixtures :users, :items, :accounts

	def test_create
		user = User.new
		user.login = 'test_1'
		user.password_plain = '123-4_56'
		user.password_confirmation = '123-4_56'
    user.email = 'test@hoge.example.com'

		assert user.save

		assert_equal user.password,Digest::SHA1.hexdigest('test_1'+'123-4_56')
		assert_not_nil user.created_at
		assert_not_nil user.updated_at
		assert_equal user.is_active?, true
	end
  
	def test_create_without_email
		user = User.new
		user.login = 'test_1'
		user.password_plain = '123-4_56'
		user.password_confirmation = '123-4_56'
    user.email = ''

		assert (not user.save)
	end

	def test_create_with_email_wrong
		user = User.new
		user.login = 'test_1'
		user.password_plain = '123-4_56'
		user.password_confirmation = '123-4_56'
    user.email = 'test.example.com'

		assert (not user.save)
	end

	def test_create_with_email_too_short
		user = User.new
		user.login = 'test_1'
		user.password_plain = '123-4_56'
		user.password_confirmation = '123-4_56'
    user.email = 't@e.c'

		assert (not user.save)
	end

	def test_accounts
		assert_not_nil users(:user1).accounts
	end
  
	def test_credit_relations
		assert_not_nil users(:user1).credit_relations
	end

	def test_create_password_not_same
		user = User.new
		user.login = 'test'
		user.password_plain = '123456'
		user.password_confirmation = '1234567'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_login_not_set
		user = User.new
		user.login = nil
		user.password_plain = '123456'
		user.password_confirmation = '123456'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_login_too_short
		user = User.new
		user.login = '11'
		user.password_plain = '123456'
		user.password_confirmation = '123456'
    user.email = 'test@example.com'
		assert (not user.save)
	end
	def test_create_login_too_long
		user = User.new
		user.login = '12345678901'
		user.password_plain = '123456'
		user.password_confirmation = '123456'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_password_not_set
		user = User.new
		user.login = 'test1'
		user.password_plain = nil
		user.password_confirmation = nil
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_password_too_short
		user = User.new
		user.login = 'test1'
		user.password_plain = '12345'
		user.password_confirmation = '12345'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_password_too_long
		user = User.new
		user.login = 'test1'
		user.password_plain = '12345678901'
		user.password_confirmation = '12345678901'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_password_illegal_char
		user = User.new
		user.login = 'test1'
		user.password_plain = '1234.56'
		user.password_confirmation = '1234.56'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_login_illegal_char
		user = User.new
		user.login = 'te.st1'
		user.password_plain = '123456'
		user.password_confirmation = '123456'
    user.email = 'test@example.com'
		assert (not user.save)
	end

	def test_create_user_exist
		user = User.new
		user.login = 'user1'
		user.password_plain = '123456'
		user.password_confirmation = '123456'
    user.email = 'test@example.com'
		assert (not user.save)

	end

	def test_update_user_with_new_password
		
		user = User.find(1)
		old_updated_at = user.updated_at
		user.password_plain = '12-3456'
		user.password_confirmation = '12-3456'

		assert user.save

		assert_equal user.password,Digest::SHA1.hexdigest('user1'+'12-3456')
		assert_not_nil user.created_at
		assert_not_equal old_updated_at, user.updated_at
	end

	def test_update_user_without_password
		
		user = User.find(1)
		user.password_plain = ''
		user.password_confirmation = ''

		assert user.save

		assert_equal Digest::SHA1.hexdigest('user1'+'123456'), user.password
		assert_not_nil user.created_at
	end


	def test_items
		user1 = users(:user1)
		assert_not_nil user1.items

		user1.items.each do |it|
			assert_not_nil it
		end
		assert_not_nil user1.items.find(:all, :conditions => ["action_date < ?", Date.new(2008,3)])
		assert_equal 0,  user1.items.find(:all, :conditions => ["user_id = 101"]).size
		assert_not_equal 0,  user1.items.find(:all, :conditions => ["user_id = 1"]).size
	end

  def test_get_separated_accounts
    user1 = users(:user1)

    h_accounts = user1.get_separated_accounts
    assert_not_equal 0, user1.accounts.count(:conditions => ["account_type IN ('account', 'income')"]), h_accounts[:from_accounts].size
    assert_equal user1.accounts.count(:conditions => ["account_type IN ('account', 'income')"]), h_accounts[:from_accounts].size
    assert_equal user1.accounts.count(:conditions => ["account_type IN ('account', 'outgo')"]), h_accounts[:to_accounts].size
    assert_equal user1.accounts.count(:conditions => ["account_type = ?", 'account']), h_accounts[:bank_accounts].size
    assert_equal user1.accounts.count(:conditions => ["account_type IN ('account', 'outgo', 'income')"]), h_accounts[:all_accounts].size
    assert_equal user1.accounts.count(:conditions =>["account_type = ? ", 'income']), h_accounts[:income_ids].size
    assert_equal user1.accounts.count(:conditions =>["account_type = ? ", 'outgo']), h_accounts[:outgo_ids].size
    assert_equal user1.accounts.count(:conditions =>["account_type = ? ", 'account']), h_accounts[:account_ids].size
    assert_equal user1.accounts.count(:conditions =>["bgcolor IS NOT NULL"]), h_accounts[:account_bgcolors].size
  end
end
