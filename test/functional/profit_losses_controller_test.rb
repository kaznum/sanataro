require 'test_helper'

class ProfitLossesControllerTest < ActionController::TestCase
  fixtures :all
	def test_index_nologin
		get :index
		assert_redirected_to login_path
  end

	def test_index_wo_month
		login
		get :index
		assert_not_nil assigns(:from_date)
    assert_equal assigns(:from_date), Date.today.beginning_of_month
		assert_not_nil assigns(:m_pls)
		assert_not_nil assigns(:account_incomes)
		assert_not_nil assigns(:total_income)
		assert_not_nil assigns(:account_outgos)
		assert_not_nil assigns(:total_outgo)
		assert_response :success
		assert_template 'index'
		assert_valid_markup
  end

	def test_pl_invalid_month
    login
    
		get :index, :year=>'2008', :month=>'13'
		assert_redirected_to current_entries_path
  end
  
	def test_index
    login
		get :index, :year => '2008', :month => '2'
		assert_not_nil assigns(:from_date)
		assert_not_nil assigns(:m_pls)
		assert_not_nil assigns(:account_incomes)
		assert_not_nil assigns(:total_income)
		assert_not_nil assigns(:account_outgos)
		assert_not_nil assigns(:total_outgo)
		assert_response :success
		assert_template 'index'
		assert_valid_markup

# 		get :index, :year=>'2008', :month=>'1'
# 		assert_equal 2008, session[:from_date].year
# 		assert_equal 1, session[:from_date].month
# 		assert_equal 1, session[:from_date].day

# 		assert_equal 2008, session[:to_date].year
# 		assert_equal 1, session[:to_date].month
# 		assert_equal 31, session[:to_date].day

	end
  
	def test_show_no_login
		xhr :get, :show, :id=>accounts(:bank1).id.to_s, :year=>'2008', :month=>'2'
		assert_rjs :redirect_to, login_path
  end

	def test_show_wo_id
		login
		xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :index
		# id がない
		xhr :get, :show, :year=>'2008', :month=>'2'
		assert_rjs :redirect_to, login_path
  end
  
	def test_show
		login
#		xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :index
		xhr :get, :show, :id=>accounts(:outgo3).id.to_s, :year=>'2008', :month=>'2'
		assert_not_nil assigns(:items)
		assert_not_nil assigns(:account_id)
    assert_equal accounts(:outgo3).id, assigns(:account_id)
    assert_equal accounts(:outgo3).id.class, assigns(:account_id).class
    assert_not_nil assigns(:separated_accounts)
		assigns(:items).each do |item|
			assert item.to_account_id == accounts(:outgo3).id
			assert item.action_date >= Date.new(2008, 2) &&  item.action_date <= Date.new(2008,2).end_of_month
		end
		assert_rjs :replace, :pl_history
		assert_template '_show'
		assert_rjs :hide, "pl_history_#{assigns(:account_id)}"
		assert_rjs :visual_effect, :appear, "pl_history_#{assigns(:account_id)}", :duration => '0.3'
	end
  
	def test_show_wo_date
		login
		xhr :get, :show, :id=>accounts(:outgo3).id.to_s
		assert_not_nil assigns(:items)
		assert_not_nil assigns(:account_id)
    assert_not_nil assigns(:separated_accounts)
    assert_equal accounts(:outgo3).id, assigns(:account_id)
    assert_equal accounts(:outgo3).id.class, assigns(:account_id).class
		assigns(:items).each do |item|
			assert item.to_account_id == accounts(:outgo3).id
			assert item.action_date >= Date.today.beginning_of_month &&  item.action_date <= Date.today.end_of_month
		end
		assert_rjs :replace, :pl_history
		assert_template '_show'
		assert_rjs :hide, "pl_history_#{assigns(:account_id)}"
		assert_rjs :visual_effect, :appear, "pl_history_#{assigns(:account_id)}", :duration => '0.3'
	end
end
