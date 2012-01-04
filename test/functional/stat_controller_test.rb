require 'test_helper'

class StatControllerTest < ActionController::TestCase
	fixtures :users, :accounts, :items, :monthly_profit_losses, :credit_relations, :autologin_keys

	def test_index
		get :index
		assert_redirected_to login_path

		login

		get :index
		assert_redirected_to current_entries_path
	end



	def test_income_graph
		get :income_graph
		assert_redirected_to login_path

		login

		get :income_graph, :year=>'2008', :month=>'2'
		assert_response :success
	end

	def test_outgo_graph
		get :outgo_graph
		assert_redirected_to login_path

		login

		get :outgo_graph, :year=>'2008', :month=>'2'
		assert_response :success
	end

	def test_asset_graph
		get :asset_graph
		assert_redirected_to login_path

		login

		get :asset_graph, :year=>'2008', :month=>'2', :is_debt=>'f'
		assert_response :success

		get :asset_graph, :year=>'2008', :month=>'2', :is_debt=>'t'
		assert_response :success
	end

	def test_show_yearly_bs_graph
		xhr :post, :show_yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :type=>'total', :year => 2008, :month => 2
		assert_select_rjs :redirect, login_path

		login
		
    # no ID
		xhr :post, :show_yearly_bs_graph, :year => 2008, :month => 2
		assert_select_rjs :redirect, login_path

    # no month
		xhr :post, :show_yearly_bs_graph, :type => 'total', :year => 2008
		assert_select_rjs :redirect, login_path

		xhr :post, :show_yearly_bs_graph, :type=>'total', :year => 2008, :month => 2
		assert_select_rjs :replace, :account_history
		assert_template '_yearly_bs_graph'
		assert_select_rjs :hide, :account_yearly_history_img_total
		assert_rjs :visual_effect, :appear, :account_yearly_history_img_total, :duration => '0.3'

		xhr :post,  :show_yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
		assert_select_rjs :replace, :account_history
		assert_template '_yearly_bs_graph'
		assert_select_rjs :hide, "account_yearly_history_img_#{accounts(:bank1).id}"
		assert_rjs :visual_effect, :appear, "account_yearly_history_img_#{accounts(:bank1).id}", :duration => '0.3'
		
	end


	def test_yearly_bs_graph
		get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
		assert_redirected_to login_path

		login

    # no id
		get :yearly_bs_graph, :year => 2008, :month => 2
		assert_redirected_to login_path

    # no month
		get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008
    assert_redirected_to login_path

		get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
		assert_response :success

		get :yearly_bs_graph, :account_id=>'10000', :year => 2008, :month => 2
		assert_redirected_to login_path

		get :yearly_bs_graph, :type=>'total', :year => 2008, :month => 2
		assert_response :success
	end


	def test_show_yearly_pl_graph
		xhr :post, :show_yearly_pl_graph, :account_id=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
		assert_select_rjs :redirect, login_path

		login

    # no id
		xhr :post, :show_yearly_pl_graph, :year => 2008, :month => 2
		assert_select_rjs :redirect, login_path

    # no month
		xhr :post, :show_yearly_pl_graph, :account_id=>accounts(:outgo3).id.to_s, :year => 2008
		assert_select_rjs :redirect, login_path

		xhr :post, :show_yearly_pl_graph, :account_id=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
		assert_select_rjs :replace, :pl_history, Regexp.new('pl_yearly_history_img_.+')
		assert_select_rjs :hide, "pl_yearly_history_img_#{accounts(:outgo3).id}"
		assert_rjs :visual_effect, :appear, "pl_yearly_history_img_#{accounts(:outgo3).id}", :duration => '0.3'

		xhr :post,  :show_yearly_pl_graph, :type=>'total', :year => 2008, :month => 2
		assert_select_rjs :replace, :pl_history, Regexp.new('pl_yearly_history_img_total.+')
		assert_select_rjs :hide, :pl_yearly_history_img_total
		assert_rjs :visual_effect, :appear, :pl_yearly_history_img_total, :duration => '0.3'

		xhr :post,  :show_yearly_pl_graph, :type=>'income_total', :year => 2008, :month => 2
		assert_select_rjs :replace, :pl_history, Regexp.new('pl_yearly_history_img_income_total.+')
		assert_select_rjs :hide, :pl_yearly_history_img_income_total
		assert_rjs :visual_effect, :appear, :pl_yearly_history_img_income_total, :duration => '0.3'

		xhr :post,  :show_yearly_pl_graph, :type=>'outgo_total', :year => 2008, :month => 2
		assert_select_rjs :replace, :pl_history, Regexp.new('pl_yearly_history_img_outgo_total.+')
		assert_select_rjs :hide, :pl_yearly_history_img_outgo_total
		assert_rjs :visual_effect, :appear, :pl_yearly_history_img_outgo_total, :duration => '0.3'
	end

	def test_yearly_pl_graph
		get :yearly_pl_graph, :type=>'total', :year => 2008, :month => 2
		assert_redirected_to login_path

		login

    # no id
		get :yearly_pl_graph, :year => 2008, :month => 2
		assert_redirected_to login_path

    # id not exist
		get :yearly_pl_graph, :account_id=>'100000', :year => 2008, :month => 2
		assert_redirected_to login_path

    # no month
		get :yearly_pl_graph, :account_id => accounts(:outgo3).id.to_s, :year => 2008
		assert_redirected_to login_path
    
		get :yearly_pl_graph, :account_id=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
		assert_response :success
		get :yearly_pl_graph, :type=>'total', :year => 2008, :month => 2
		assert_response :success
		get :yearly_pl_graph, :type=>'income_total', :year => 2008, :month => 2
		assert_response :success
		get :yearly_pl_graph, :type=>'outgo_total', :year => 2008, :month => 2
		assert_response :success
	end

	def test_change_month
		xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :pl
		assert_select_rjs :redirect, login_path

		get :change_month, :year=>'2008', :month=>'2', :current_action => :pl
		assert_redirected_to login_path

		post :change_month, :year=>'2008', :month=>'2', :current_action => :pl
		assert_redirected_to login_path

		login

		xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :index
		assert_select_rjs :redirect, @controller.url_for(:action => :index, :year => '2008', :month => '2', :only_path => true)

		get :change_month, :year=>'2008', :month=>'2', :current_action => 'aaa'
		assert_redirected_to :action => 'aaa', :year=>'2008', :month=>'2'

		post :change_month, :year=>'2008', :month=>'2', :current_action => 'bbb'
		assert_redirected_to :action => 'bbb', :year=>'2008', :month=>'2'
	end

end
