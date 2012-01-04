# -*- coding: utf-8 -*-
require 'test_helper'

class EntriesControllerTest < ActionController::TestCase
  fixtures :all
  def test_items_no_login
    get :index
    assert_response :redirect
    assert_redirected_to login_path
  end

  def test_items_without_month
    login
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:items)
    assert_equal Date.today, assigns(:new_item).action_date
    assert_tag :tag=>'a', :attributes=>{:href=>/logout/}
    assert_tag :tag=>'input', :attributes => {:type => 'checkbox', :id => 'confirmation_required', :name => 'confirmation_required', :value => 'true', :checked => nil}
  end
  
  def test_items
    login

    get :index, :year => Date.today.year, :month => Date.today.month
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:separated_accounts)
    # placeholder属性がW3Cで規定されていないためチェックがとおらない
#   assert_valid_markup
#    assert_tag :tag=>'a', :attributes=>{:href=>/login\/do_logout/}
    assert_tag :tag=>'a', :attributes=>{:href=>/logout/}
    assert_tag :tag=>'input', :attributes => {:type => 'checkbox', :id => 'confirmation_required', :name => 'confirmation_required', :value => 'true', :checked => nil}


#    xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action=>'items'
    get :index, :year => '2008', :month => '2'
    assert_equal Date.new(2008,2), assigns(:new_item).action_date
    assert_response :success
    assert_template 'index'
    assert_tag :tag=>'div', :attributes => {:id => 'item_1'}, :child => { :tag => 'div', :attributes => { :class => 'item_name' }, :child => { :tag => 'a', :attributes => {:class =>'item_confirmation_required'}}}
    assert_no_tag :tag=>'div', :attributes => {:id => 'item_3'}, :child => { :tag => 'div', :attributes => { :class => 'item_name'}, :child => { :tag => 'a', :attributes => {:class =>'item_confirmation_required'}}}
    assert_not_nil assigns(:separated_accounts)


    # 日付が不正
    get :index, :year=>'2008', :month=>'13'
    assert_redirected_to current_entries_path
  end

  def test_new_no_login
    xhr :get, :new
    assert_select_rjs :redirect, login_path
  end
  
  def test_new
    login
    xhr :get, :new
    # view test
    now = Time.now
    assert_select_rjs :replace_html, "input_item_area" do
      assert_select "form#do_add_item[action=#{entries_path(now.year, now.month)}]"
    end
    assert_template '_add_item'
  end

  def test_new_item_w_month
    login
    xhr :get, :new, :year => '2008', :month => '5'
    assert_select_rjs :replace_html, :input_item_area
    assert_template '_add_item'
  end
  
  def test_new_item_different_month
    _login_and_change_month(2008,2)
    xhr :get, :new
    assert_select_rjs :replace_html, :input_item_area
    assert_template '_add_item'
  end
  
  def test_new_adjustment
    login
    xhr :get, :new, :entry_type => 'adjustment'
    assert_select_rjs :replace_html, :input_item_area
    assert_template '_add_adjustment'
    assert_equal Date.today, assigns(:action_date)
  end

  def test_new_adjustment_with_invalid_date
    assert_new_adjustment_with_year_and_month(2001,13)
    assert_equal Date.today, assigns(:action_date)
  end
  def assert_new_adjustment_with_year_and_month(year, month)
    login
    xhr :get, :new, :entry_type => 'adjustment', :year => year, :month => month
    assert_select_rjs :replace_html, :input_item_area
    assert_template '_add_adjustment'
  end
  
  def test_new_adjustment_with_year_and_month
    assert_new_adjustment_with_year_and_month(2005,11)
    assert_equal Date.new(2005, 11), assigns(:action_date)
  end
  def test_new_adjustment_with_this_month
    today = Date.today
    assert_new_adjustment_with_year_and_month(today.year,today.month)
    assert_equal Date.today, assigns(:action_date)
  end

  def test_new_simple
    login(true)
    get :new, :entry_type => 'simple'
    assert_response :success
    assert assigns(:data)
    assert_not_nil assigns(:data)[:authenticity_token]
    assert_not_nil assigns(:data)[:from_accounts]
    assert_not_nil assigns(:data)[:to_accounts]
    assert_equal Date.today.year, assigns(:data)[:year]
    assert_equal Date.today.month, assigns(:data)[:month]
    assert_equal Date.today.day, assigns(:data)[:day]

    assert_template 'new_simple'
    assert_tag :tag=>'div', :attributes=>{ :id => 'replaced_area' }
  end


  def test_create_no_login
    xhr :post, :create
    assert_select_rjs :redirect, login_path
  end

  def test_create_invalid_inputs
    login

    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)


    init_item_count = Item.count

    # 入力値が不正
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :year => Date.today.year, :month => Date.today.month
    assert_select_rjs :replace_html, :warning, /Input value/
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
    assert_equal init_item_count, Item.count
  end
  
  def test_create
    login

    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)


    init_item_count = Item.count

    # 正常処理(confirmation_required == true)
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :confirmation_required => 'true', :year => Date.today.year.to_s, :month => Date.today.month.to_s, :tag_list => 'hoge fuga'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + Date.today.strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, :candidates, ''
#   assert_select_rjs :page, /.*/, :visual_effect, :highlight
    added_item_count = Item.count
    assert_equal init_item_count + 1, added_item_count

    id = Item.maximum('id')
    new_item = Item.find_by_id(id)
    assert_equal 'テスト10', new_item.name
    assert_equal 10000, new_item.amount
    assert new_item.confirmation_required?
    
    assert_equal 'hoge fuga'.split(" ").sort.join(" "), new_item.tag_list
    tags = Tag.find_all_by_name('hoge')
    assert_equal 1, tags.size
    tags.each do |t|
      taggings = Tagging.find_all_by_tag_id(t.id)
      assert_equal 1, taggings.size
      taggings.each do |tgg|
        assert_equal users(:user1).id, tgg.user_id
        assert_equal 'Item', tgg.taggable_type
      end
    end
    

    # 正常処理(confirmation_required == nil)
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :confirmation_required => '', :year => Date.today.year, :month => Date.today.month
    added_item_count_2 = Item.count
    assert_equal added_item_count + 1, added_item_count_2
    id = Item.maximum('id')
    new_item = Item.find_by_id(id)
    assert_equal 'テスト10', new_item.name
    assert (not new_item.confirmation_required?)
    assert_equal Date.today.beginning_of_month, assigns(:display_year_month)


    # 正常処理(amountが数式)
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'(10 + 10)/40*20', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :confirmation_required => '', :year => Date.today.year, :month => Date.today.month
    added_item_count_3 = Item.count
    assert_equal added_item_count_2 + 1, added_item_count_3
    id = Item.maximum('id')
    new_item_2 = Item.find_by_id(id)
    assert_equal 10, new_item_2.amount

    # amountが数式だが不正な演算子が存在
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'@user.id', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :confirmation_required => '', :year => Date.today.year, :month => Date.today.month
    added_item_count_4 = Item.count
    assert_equal added_item_count_3 , added_item_count_4
    assert_select_rjs :replace_html, :warning
    assert_no_rjs :insert_html, :bottom, "items"
    assert_no_rjs :replace_html, :candidates, ''
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
    # amountが数式だが不正な数式
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'(10+20*2.01', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :confirmation_required => '', :year => Date.today.year, :month => Date.today.month
    assert_select_rjs :replace_html, :warning
    assert_no_rjs :insert_html, :bottom, :items
    assert_no_rjs :replace_html, :candidates, ''
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
  end
  
  #################################################
  # iphone等で追加機能のみ表示する場合(登録処理)
  #################################################
  def test_create_only_add_with_no_login
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :only_add=>'true'
    assert_select_rjs :redirect, login_path
  end

  def test_create_only_add_with_invalid_method
    login(true)
    get :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :only_add=>'true'
    assert_redirected_to login_path
  end

  def test_create_only_add_with_invalid_params
    init_item_count = Item.count
    login(true)
    
    # 入力値が不正
    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :only_add=>'true'
    assert_select_rjs :replace_html, :warning, /Input value/
    assert_rjs :visual_effect, :pulsate, :warning, :duration => PULSATE_DURATION
    assert_equal init_item_count, Item.count
  end
  
  def test_create_only_add
    login(true)
    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)
    init_item_count = Item.count

    xhr :post, :create, :action_year=>Date.today.year.to_s, :action_month=>Date.today.month.to_s, :action_day=>Date.today.day.to_s,  :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :only_add=>'true'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + Date.today.strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_no_rjs :insert_html, :bottom, "items"
    assert_select_rjs :replace_html, :candidates, ''
    assert_nil assigns(:display_year_month)
    added_item_count = Item.count
    assert_equal init_item_count + 1, added_item_count
  end

  def test_create_correct_data
    _login_and_change_month(2008,2)
    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)
    init_pl0712 = monthly_profit_losses(:bank1200712)
    init_pl0801 = monthly_profit_losses(:bank1200801)
    init_pl0802 = monthly_profit_losses(:bank1200802)
    init_pl0803 = monthly_profit_losses(:bank1200803)

    # adj2以前
    xhr :post, :create,
    :action_year=>(init_adj2.action_date - 1).year.to_s,
    :action_month=>(init_adj2.action_date - 1).month.to_s,
    :action_day=>(init_adj2.action_date - 1).day.to_s,
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    assert_no_rjs :replace_html, :account_status, account_status_path
    assert_no_rjs :replace_html, :confirmation_status, confirmation_status_path
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + (init_adj2.action_date - 1).strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/


    act1_adj2 = Item.find(items(:adjustment2).id)
    act1_adj4 = Item.find(items(:adjustment4).id)
    act1_adj6 = Item.find(items(:adjustment6).id)
    act1_pl0712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    act1_pl0801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    act1_pl0802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    act1_pl0803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal init_adj2.amount + 10000, act1_adj2.amount
    assert_equal init_adj4.amount, act1_adj4.amount
    assert_equal init_adj6.amount, act1_adj6.amount

    assert_equal init_pl0712.amount, act1_pl0712.amount
    assert_equal init_pl0801.amount, act1_pl0801.amount
    assert_equal init_pl0802.amount, act1_pl0802.amount
    assert_equal init_pl0803.amount, act1_pl0803.amount


    # adj2とadj4の間
    xhr :post, :create,
    :action_year=>(init_adj4.action_date - 1).year.to_s,
    :action_month=>(init_adj4.action_date - 1).month.to_s,
    :action_day=>(init_adj4.action_date - 1).day.to_s,
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    act2_adj2 = Item.find(items(:adjustment2).id)
    act2_adj4 = Item.find(items(:adjustment4).id)
    act2_adj6 = Item.find(items(:adjustment6).id)

    assert_equal act1_adj2.amount, act2_adj2.amount
    assert_equal act1_adj4.amount + 10000, act2_adj4.amount
    assert_equal act1_adj6.amount, act2_adj6.amount

    act2_pl0712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    act2_pl0801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    act2_pl0802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    act2_pl0803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
    act2_pl0802_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,2,1)])
    act2_pl0803_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,3,1)])
    act2_pl0802_outgo_amount = act2_pl0802_outgo.nil? ? 0 : act2_pl0802_outgo.amount
    act2_pl0803_outgo_amount = act2_pl0803_outgo.nil? ? 0 : act2_pl0803_outgo.amount

    assert_equal act1_pl0712.amount, act2_pl0712.amount
    assert_equal act1_pl0801.amount, act2_pl0801.amount
    assert_equal act1_pl0802.amount, act2_pl0802.amount
    assert_equal act1_pl0803.amount, act2_pl0803.amount


    # adj4とadj6の間(adj4と同じ月)
    xhr :post, :create,
    :action_year=>(init_adj4.action_date + 1).year.to_s,
    :action_month=>(init_adj4.action_date + 1).month.to_s,
    :action_day=>(init_adj4.action_date + 1).day.to_s,
    :item_name=>'テスト10', :amount=>'10,100', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    assert_no_rjs :replace_html, :account_status, /#{Regexp.escape(account_status_path)}/
      assert_no_rjs :replace_html, :confirmation_status, /#{Regexp.escape(confirmation_status_path)}/
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + (init_adj4.action_date + 1).strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10100) + 'yen'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    act3_adj2 = Item.find(items(:adjustment2).id)
    act3_adj4 = Item.find(items(:adjustment4).id)
    act3_adj6 = Item.find(items(:adjustment6).id)

    assert_equal act2_adj2.amount, act3_adj2.amount
    assert_equal act2_adj4.amount, act3_adj4.amount
    assert_equal act2_adj6.amount + 10100, act3_adj6.amount



    act3_pl0712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    act3_pl0801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    act3_pl0802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    act3_pl0803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
    act3_pl0802_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,2,1)])
    act3_pl0803_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,3,1)])
    act3_pl0802_outgo_amount = act3_pl0802_outgo.nil? ? 0 : act3_pl0802_outgo.amount
    act3_pl0803_outgo_amount = act3_pl0803_outgo.nil? ? 0 : act3_pl0803_outgo.amount

    assert_equal act2_pl0712.amount, act3_pl0712.amount
    assert_equal act2_pl0801.amount, act3_pl0801.amount
    assert_equal act2_pl0802.amount - 10100, act3_pl0802.amount
    assert_equal act2_pl0803.amount + 10100, act3_pl0803.amount
    assert_equal act2_pl0802_outgo_amount + 10100, act3_pl0802_outgo_amount
    assert_equal act2_pl0803_outgo_amount, act3_pl0803_outgo_amount



    # adj4とadj6の間(adj6と同じ月)
    xhr :post, :create,
    :action_year=>(init_adj6.action_date - 1).year.to_s,
    :action_month=>(init_adj6.action_date - 1).month.to_s,
    :action_day=>(init_adj6.action_date - 1).day.to_s,
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + (init_adj6.action_date - 1).strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'

    act4_adj2 = Item.find(items(:adjustment2).id)
    act4_adj4 = Item.find(items(:adjustment4).id)
    act4_adj6 = Item.find(items(:adjustment6).id)

    assert_equal act3_adj2.amount, act4_adj2.amount
    assert_equal act3_adj4.amount, act4_adj4.amount
    assert_equal act3_adj6.amount + 10000, act4_adj6.amount

    act4_pl0712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    act4_pl0801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    act4_pl0802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    act4_pl0803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
    act4_pl0802_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,2,1)])
    act4_pl0803_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,3,1)])
    act4_pl0802_outgo_amount = act4_pl0802_outgo.nil? ? 0 : act4_pl0802_outgo.amount
    act4_pl0803_outgo_amount = act4_pl0803_outgo.nil? ? 0 : act4_pl0803_outgo.amount

    assert_equal act3_pl0712.amount, act4_pl0712.amount
    assert_equal act3_pl0801.amount, act4_pl0801.amount
    assert_equal act3_pl0802.amount, act4_pl0802.amount
    assert_equal act3_pl0803.amount, act4_pl0803.amount
    assert_equal act3_pl0802_outgo_amount, act4_pl0802_outgo_amount
    assert_equal act3_pl0803_outgo_amount + 10000, act4_pl0803_outgo_amount


    # adj6以降
    xhr :post, :create,
    :action_year=>(init_adj6.action_date + 1).year.to_s,
    :action_month=>(init_adj6.action_date + 1).month.to_s,
    :action_day=>(init_adj6.action_date + 1).day.to_s,
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    act5_adj2 = Item.find(items(:adjustment2).id)
    act5_adj4 = Item.find(items(:adjustment4).id)
    act5_adj6 = Item.find(items(:adjustment6).id)

    assert_equal act4_adj2.amount, act5_adj2.amount
    assert_equal act4_adj4.amount, act5_adj4.amount
    assert_equal act4_adj6.amount, act5_adj6.amount


    act5_pl0712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    act5_pl0801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    act5_pl0802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    act5_pl0803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
    act5_pl0802_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,2,1)])
    act5_pl0803_outgo = MonthlyProfitLoss.find(:first,
                         :conditions=>["account_id = ? and month = ?",
                                accounts(:outgo3).id, Date.new(2008,3,1)])
    act5_pl0802_outgo_amount = act5_pl0802_outgo.nil? ? 0 : act5_pl0802_outgo.amount
    act5_pl0803_outgo_amount = act5_pl0803_outgo.nil? ? 0 : act5_pl0803_outgo.amount

    assert_equal act4_pl0712.amount, act5_pl0712.amount
    assert_equal act4_pl0801.amount, act5_pl0801.amount
    assert_equal act4_pl0802.amount, act5_pl0802.amount
    assert_equal act4_pl0803.amount - 10000, act5_pl0803.amount
    assert_equal act4_pl0802_outgo_amount, act5_pl0802_outgo_amount
    assert_equal act4_pl0803_outgo_amount + 10000, act5_pl0803_outgo_amount
  end

  #
  # クレジットカード情報の登録
  #
  def test_create_credit
    _login_and_change_month(2008,2)

    xhr :post, :create,
    :action_year=>'2008',
    :action_month=>'2',
    :action_day=>'10',
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:credit4).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + '2008/02/10' + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    credit_item = Item.find(:first, :conditions=>["action_date = ? and from_account_id = ? and to_account_id = ? and amount = ? and child_id is not null and parent_id is null",
                          Date.new(2008,2,10), accounts(:credit4).id, accounts(:outgo3).id, 10000])
    assert_not_nil credit_item
    assert_equal 10000, credit_item.amount
    assert_nil credit_item.parent_id
    assert_not_nil credit_item.child_id
    assert_equal 1, Item.count(:conditions=>["parent_id = ? and child_id is null", credit_item.id])
    payment_item = Item.find(:first, :conditions=>["parent_id = ?", credit_item.id])
    assert_not_nil payment_item
    assert_equal credit_item.child_id, payment_item.id
    assert_equal credit_item.id, payment_item.parent_id
    assert_equal Date.new(2008, 2 + credit_relations(:cr1).payment_month,credit_relations(:cr1).payment_day), payment_item.action_date
    assert_equal credit_relations(:cr1).payment_account_id, payment_item.from_account_id
    assert_equal credit_relations(:cr1).credit_account_id, payment_item.to_account_id
    assert_equal 10000, payment_item.amount
  end

  #
  # クレジットカード情報の登録(settlement_dayよりaction_dateが大きい場合)
  #
  def test_create_credit_after_settlement_day
    cr1 = credit_relations(:cr1)
    cr1.settlement_day = 15
    assert cr1.save

    _login_and_change_month(2008,2)

    xhr :post, :create,
    :action_year=>'2008',
    :action_month=>'2',
    :action_day=>'25',
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:credit4).id, :to=>accounts(:outgo3).id,
    :year => 2008, :month => 2

    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + '2008/02/25' + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    credit_item = Item.find(:first, :conditions=>["action_date = ? and from_account_id = ? and to_account_id = ? and amount = ? and child_id is not null and parent_id is null",
                          Date.new(2008,2,25), accounts(:credit4).id, accounts(:outgo3).id, 10000])
    assert_not_nil credit_item
    assert_equal 10000, credit_item.amount
    assert_nil credit_item.parent_id
    assert_not_nil credit_item.child_id
    assert_equal 1, Item.count(:conditions=>["parent_id = ? and child_id is null", credit_item.id])
    payment_item = Item.find(:first, :conditions=>["parent_id = ?", credit_item.id])
    assert_not_nil payment_item
    assert_equal credit_item.child_id, payment_item.id
    assert_equal credit_item.id, payment_item.parent_id
    assert_equal Date.new(2008, 3 + credit_relations(:cr1).payment_month,credit_relations(:cr1).payment_day), payment_item.action_date
    assert_equal credit_relations(:cr1).payment_account_id, payment_item.from_account_id
    assert_equal credit_relations(:cr1).credit_account_id, payment_item.to_account_id
    assert_equal 10000, payment_item.amount
  end

  #
  # クレジットカード情報の登録
  #
  def test_create_credit_payment_date_99
    cr1 = credit_relations(:cr1)
    cr1.payment_day = 99
    assert cr1.save
    _login_and_change_month(2008,2)
    
    xhr :post, :create,
    :action_year=>'2008',
    :action_month=>'2',
    :action_day=>'10',
    :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:credit4).id, :to=>accounts(:outgo3).id,
    :year => 2008,
    :month => 2

    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    #assert_select_rjs :page, :warning, :style, :color=, 'blue'
    assert_select_rjs :replace_html, :warning, 'Item was added successfully.' + ' ' + '2008/02/10' + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(10000) + 'yen'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    credit_item = Item.find(:first, :conditions=>["action_date = ? and from_account_id = ? and to_account_id = ? and amount = ? and child_id is not null and parent_id is null",
                          Date.new(2008,2,10), accounts(:credit4).id, accounts(:outgo3).id, 10000])
    assert_not_nil credit_item
    assert_equal 10000, credit_item.amount
    assert_nil credit_item.parent_id
    assert_not_nil credit_item.child_id
    assert_equal 1, Item.count(:conditions=>["parent_id = ? and child_id is null", credit_item.id])
    payment_item = Item.find(:first, :conditions=>["parent_id = ?", credit_item.id])
    assert_not_nil payment_item
    assert_equal credit_item.child_id, payment_item.id
    assert_equal credit_item.id, payment_item.parent_id
    assert_equal (Date.new(2008, 2 + cr1.payment_month + 1,1) - 1).strftime("%Y/%m/%d"), payment_item.action_date.strftime("%Y/%m/%d")
    assert_equal cr1.payment_account_id, payment_item.from_account_id
    assert_equal cr1.credit_account_id, payment_item.to_account_id
    assert_equal 10000, payment_item.amount
  end

  #################################
  # 残高調整の登録
  #################################
  def test_create_adjustment_with_no_login
    xhr :post, :create, :action_year=>'2008', :action_month=>'2', :action_day=>'5', :from=>'-1', :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :entry_type => 'adjustment'
    assert_select_rjs :redirect, login_path
  end
  
  def test_create_adjustment
    login

    last_count = Item.count
    # rack of params
    xhr :post, :create, :action_month=>'2', :action_day=>'5', :from=>'-1', :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :entry_type => 'adjustment', :year => 2008, :month => 2
    assert_select_rjs_warning(/Date/)
    assert_equal last_count, Item.count
  end

  #
  # before adj2
  #
  def test_create_adjustment_before_adj2
    _login_and_change_month(2008,2)
    
    last_count = Item.count
    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)

    date = items(:adjustment2).action_date - 1

    b_pl200712 = monthly_profit_losses(:bank1200712)
    b_pl200801 = monthly_profit_losses(:bank1200801)
    b_pl200802 = monthly_profit_losses(:bank1200802)
    b_pl200803 = monthly_profit_losses(:bank1200803)

    a1_sum_before = Item.sum('amount',
                 :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])

    a1_sum_before = (a1_sum_before.nil? ? 0 : a1_sum_before)

    # methodが不正
    get :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :year => 2008, :month => 2
    assert_redirected_to login_path #:controller => :login, :action => :login

    # amountが不正な数式
    xhr :post,  :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000-(10', :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'

    # 正常(しかも数式)
    xhr :post,  :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'100*(10+50)/2', :year => 2008, :month => 2, :tag_list => 'hoge fuga'
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning, 'Item was added successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' Adjustment ' + CommonUtil.separate_by_comma(3000) + 'yen'

    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/
    # データの整合性
    
    
    #
    # 1行追加されていることを確認
    #
    assert_equal last_count + 1, Item.count

    a1_adj2 = Item.find(items(:adjustment2).id)
    a1_adj4 = Item.find(items(:adjustment4).id)
    a1_adj6 = Item.find(items(:adjustment6).id)
    a_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    a_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    a_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    a_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    #追加された adjustmentオブジェクト
    added_adj = Item.find(:first, :conditions=>["user_id = ? and action_date = ?", users(:user1).id, date])
    a1_sum_after = Item.sum('amount',
                :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                      users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])
    a1_sum_after = (a1_sum_after.nil? ? 0 : a1_sum_after)

    assert_equal 3000, added_adj.adjustment_amount
    assert_equal 3000 - a1_sum_before, added_adj.amount
    assert_equal a1_sum_after, added_adj.amount + a1_sum_before

    assert_equal init_adj2.amount - added_adj.amount, a1_adj2.amount

    assert_equal b_pl200712.amount, a_pl200712.amount
    assert_equal b_pl200801.amount, a_pl200801.amount
    assert_equal b_pl200802.amount, a_pl200802.amount
    assert_equal b_pl200803.amount, a_pl200803.amount
    
    # tag
    assert_equal 'hoge fuga'.split(" ").sort.join(" "), added_adj.tag_list
    tags = Tag.find_all_by_name('hoge')
    assert_equal 1, tags.size
    tags.each do |t|
      taggings = Tagging.find_all_by_tag_id(t.id)
      assert_equal 1, taggings.size
      taggings.each do |tgg|
        assert_equal users(:user1).id, tgg.user_id
        assert_equal 'Item', tgg.taggable_type
      end
    end
  end

  # between adj2 and adj4
  def test_create_adjustment_between_adj2_and_adj4
    _login_and_change_month(2008,2)

    date = items(:adjustment4).action_date - 1
    init_adj2 = items(:adjustment2)
    init_adj4 = items(:adjustment4)
    init_adj6 = items(:adjustment6)

    b_pl200712 = monthly_profit_losses(:bank1200712)
    b_pl200801 = monthly_profit_losses(:bank1200801)
    b_pl200802 = monthly_profit_losses(:bank1200802)
    b_pl200803 = monthly_profit_losses(:bank1200803)

    a1_sum_before = Item.sum('amount',
                 :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])

    a1_sum_before = (a1_sum_before.nil? ? 0 : a1_sum_before)

    xhr :post,  :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning, 'Item was added successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' Adjustment ' + CommonUtil.separate_by_comma(3000) + 'yen'

    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    # 整合性チェック
    added_adj = Item.find(:first,
              :conditions=>["user_id = ? and action_date = ? and is_adjustment = ? and to_account_id = ?",
                      users(:user1).id, date, true, accounts(:bank1).id])
    a1_adj2 = Item.find(items(:adjustment2).id)
    a1_adj4 = Item.find(items(:adjustment4).id)
    a1_adj6 = Item.find(items(:adjustment6).id)

    a_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    a_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    a_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    a_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    a1_sum_after = Item.sum('amount',
                :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                      users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])
    a1_sum_after = (a1_sum_after.nil? ? 0 : a1_sum_after)

    assert_equal 3000, added_adj.adjustment_amount
    assert_equal 3000 - a1_sum_before, added_adj.amount
    assert_equal a1_sum_after, added_adj.amount + a1_sum_before

    assert_equal init_adj2.amount, a1_adj2.amount
    assert_equal init_adj4.amount - added_adj.amount, a1_adj4.amount
    assert_equal init_adj6.amount, a1_adj6.amount

    assert_equal b_pl200712.amount, a_pl200712.amount
    assert_equal b_pl200801.amount, a_pl200801.amount
    assert_equal b_pl200802.amount, a_pl200802.amount
    assert_equal b_pl200803.amount, a_pl200803.amount
  end

  # between adj4 and adj6 (the month is same as adj4)
  def test_create_adjustment_between_adj4_and_adj6_same_month_as_adj4
    _login_and_change_month(2008,2)

    date = items(:adjustment4).action_date + 1
    init_adj2 = items(:adjustment2)
    init_adj4 = items(:adjustment4)
    init_adj6 = items(:adjustment6)

    b_pl200712 = monthly_profit_losses(:bank1200712)
    b_pl200801 = monthly_profit_losses(:bank1200801)
    b_pl200802 = monthly_profit_losses(:bank1200802)
    b_pl200803 = monthly_profit_losses(:bank1200803)

    a1_sum_before = Item.sum('amount',
                 :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])

    a1_sum_before = (a1_sum_before.nil? ? 0 : a1_sum_before)

    xhr :post, :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning, 'Item was added successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' Adjustment ' + CommonUtil.separate_by_comma(3000) + 'yen'

    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :insert_html, :bottom, :items, /Show All/

    # 整合性チェック
    added_adj = Item.find(:first,
              :conditions=>["user_id = ? and action_date = ? and is_adjustment = ? and to_account_id = ?",
                      users(:user1).id, date, true, accounts(:bank1).id])
    a1_adj2 = Item.find(items(:adjustment2).id)
    a1_adj4 = Item.find(items(:adjustment4).id)
    a1_adj6 = Item.find(items(:adjustment6).id)

    a_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    a_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    a_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    a_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    a1_sum_after = Item.sum('amount',
                :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                      users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])
    a1_sum_after = (a1_sum_after.nil? ? 0 : a1_sum_after)

    assert_equal 3000, added_adj.adjustment_amount
    assert_equal 3000 - a1_sum_before, added_adj.amount
    assert_equal a1_sum_after, added_adj.amount + a1_sum_before

    assert_equal init_adj2.amount, a1_adj2.amount
    assert_equal init_adj4.amount, a1_adj4.amount
    assert_equal init_adj6.amount - added_adj.amount, a1_adj6.amount

    assert_equal b_pl200712.amount, a_pl200712.amount
    assert_equal b_pl200801.amount, a_pl200801.amount
    assert_equal b_pl200802.amount + added_adj.amount, a_pl200802.amount
    assert_equal b_pl200803.amount - added_adj.amount, a_pl200803.amount
  end

  # between adj4 and adj6 (the month is same as adj6)
  def test_create_adjustment_between_adj4_and_adj6_same_month_as_adj6
    login
    date = items(:adjustment6).action_date - 1
    init_adj2 = items(:adjustment2)
    init_adj4 = items(:adjustment4)
    init_adj6 = items(:adjustment6)

    b_pl200712 = monthly_profit_losses(:bank1200712)
    b_pl200801 = monthly_profit_losses(:bank1200801)
    b_pl200802 = monthly_profit_losses(:bank1200802)
    b_pl200803 = monthly_profit_losses(:bank1200803)

    a1_sum_before = Item.sum('amount',
                 :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])

    a1_sum_before = (a1_sum_before.nil? ? 0 : a1_sum_before)

    xhr :post, :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning, 'Item was added successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' Adjustment ' + CommonUtil.separate_by_comma(3000) + 'yen'

    # 整合性チェック
    added_adj = Item.find(:first,
              :conditions=>["user_id = ? and action_date = ? and is_adjustment = ? and to_account_id = ?",
                      users(:user1).id, date, true, accounts(:bank1).id])
    a1_adj2 = Item.find(items(:adjustment2).id)
    a1_adj4 = Item.find(items(:adjustment4).id)
    a1_adj6 = Item.find(items(:adjustment6).id)

    a_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    a_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    a_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    a_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    a1_sum_after = Item.sum('amount',
                :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                      users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])
    a1_sum_after = (a1_sum_after.nil? ? 0 : a1_sum_after)

    assert_equal 3000, added_adj.adjustment_amount
    assert_equal 3000 - a1_sum_before, added_adj.amount
    assert_equal a1_sum_after, added_adj.amount + a1_sum_before

    assert_equal init_adj2.amount, a1_adj2.amount
    assert_equal init_adj4.amount, a1_adj4.amount
    assert_equal init_adj6.amount - added_adj.amount, a1_adj6.amount

    assert_equal b_pl200712.amount, a_pl200712.amount
    assert_equal b_pl200801.amount, a_pl200801.amount
    assert_equal b_pl200802.amount, a_pl200802.amount
    assert_equal b_pl200803.amount, a_pl200803.amount
  end

  # after adj6
  def test_create_adjustment_after_adj6
    login
    date = items(:adjustment6).action_date + 1
    init_adj2 = items(:adjustment2)
    init_adj4 = items(:adjustment4)
    init_adj6 = items(:adjustment6)

    b_pl200712 = monthly_profit_losses(:bank1200712)
    b_pl200801 = monthly_profit_losses(:bank1200801)
    b_pl200802 = monthly_profit_losses(:bank1200802)
    b_pl200803 = monthly_profit_losses(:bank1200803)

    a1_sum_before = Item.sum('amount',
                 :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])

    a1_sum_before = (a1_sum_before.nil? ? 0 : a1_sum_before)

    xhr :post, :create, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :to=>accounts(:bank1).id.to_s, :adjustment_amount=>'3000', :year => Date.today.year, :month => Date.today.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html,  :warning, 'Item was added successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' Adjustment ' + CommonUtil.separate_by_comma(3000) + 'yen'

    # 整合性チェック
    added_adj = Item.find(:first,
              :conditions=>["user_id = ? and action_date = ? and is_adjustment = ? and to_account_id = ?",
                      users(:user1).id, date, true, accounts(:bank1).id])
    a1_adj2 = Item.find(items(:adjustment2).id)
    a1_adj4 = Item.find(items(:adjustment4).id)
    a1_adj6 = Item.find(items(:adjustment6).id)

    a_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    a_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    a_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    a_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    a1_sum_after = Item.sum('amount',
                :conditions=>["user_id = ? and action_date <= ? and to_account_id = ?",
                      users(:user1).id, date, accounts(:bank1).id]) -
      Item.sum('amount', :conditions=>["user_id = ? and action_date <= ? and from_account_id = ?",
                       users(:user1).id, date, accounts(:bank1).id])
    a1_sum_after = (a1_sum_after.nil? ? 0 : a1_sum_after)

    assert_equal 3000, added_adj.adjustment_amount
    assert_equal 3000 - a1_sum_before, added_adj.amount
    assert_equal a1_sum_after, added_adj.amount + a1_sum_before

    assert_equal init_adj2.amount, a1_adj2.amount
    assert_equal init_adj4.amount, a1_adj4.amount
    assert_equal init_adj6.amount, a1_adj6.amount

    assert_equal b_pl200712.amount, a_pl200712.amount
    assert_equal b_pl200801.amount, a_pl200801.amount
    assert_equal b_pl200802.amount, a_pl200802.amount
    assert_equal b_pl200803.amount + added_adj.amount, a_pl200803.amount
  end

  ##########################################################################################
  #### 削除処理 ############################################################################
  ##########################################################################################
  #
  # itemの削除の通常処理
  #
  def test_destroy_with_no_login
    old_item1 = items(:item1)
    xhr :delete, :destroy, :id=>old_item1.id, :year => old_item1.action_date.year, :month => old_item1.action_date.month
    assert_select_rjs :redirect, login_path
  end

  def test_destroy_item_no_id
    login
    xhr :delete, :destroy, :id=>nil, :year => 2008, :month => 2
    assert_select_rjs :redirect, login_path
  end

  #
  # 未来のadjが存在する場合の削除処理
  #
  def test_destroy_item_regular_having_future_adj
    old_item1 = items(:item1)
    old_adj2 = items(:adjustment2)
    old_bank1pl = monthly_profit_losses(:bank1200802)
    old_outgo3pl = monthly_profit_losses(:outgo3200802)

    _login_and_change_month(2008,2)

    xhr :delete, :destroy, :id=>old_item1.id, :year => old_item1.action_date.year, :month => old_item1.action_date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :warning, Regexp.new(old_item1.name)
    assert_select_rjs :remove, 'item_' + old_item1.id.to_s
    assert_rjs :visual_effect, :fade, 'item_' + old_item1.id.to_s, :duration => '0.3'
    assert_select_rjs :replace, 'item_' + old_adj2.id.to_s
    assert_rjs :visual_effect, :highlight, 'item_' + old_adj2.id.to_s, :duration => HIGHLIGHT_DURATION

    new_adj2 = Item.find(old_adj2.id)
    assert_nil Item.find(:first, :conditions=>["id = ?", old_item1.id])
    new_bank1pl = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new_outgo3pl = MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200802).id)

    assert_equal old_adj2.amount - old_item1.amount, new_adj2.amount
    assert_equal old_bank1pl.amount, new_bank1pl.amount
    assert_equal old_outgo3pl.amount - old_item1.amount, new_outgo3pl.amount
  end

  #
  # 未来のadjが存在しない場合の削除処理
  #
  def test_destroy_item_regular_not_having_future_adj
    _login_and_change_month(2008,2)

    # dummy data
    xhr :post, :create, :item_name=>'test', :amount=>'1000', :action_year=>'2008', :action_month=>'2', :action_day=>'25',:from=>'11', :to=>'13', :year => 2008, :month => 2
    item = Item.find(:first, :conditions=>["name = 'test' and from_account_id = 11 and to_account_id = 13"])
    old_bank11pl = MonthlyProfitLoss.find(:first, :conditions=>["account_id = ? and month = ?", 11, Date.new(2008,2)])
    old_outgo13pl = MonthlyProfitLoss.find(:first, :conditions=>["account_id = ? and month = ?", 13, Date.new(2008,2)])


    xhr :delete, :destroy, :id=>item.id, :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :warning, Regexp.new(item.name)
    assert_select_rjs :remove, "item_#{item.id}"

    new_bank11pl = MonthlyProfitLoss.find(old_bank11pl.id)
    new_outgo13pl = MonthlyProfitLoss.find(old_outgo13pl.id)
    assert_nil Item.find(:first, :conditions=>["name = 'test' and from_account_id = 11 and to_account_id = 13"])

    assert_equal old_bank11pl.amount + item.amount, new_bank11pl.amount
    assert_equal old_outgo13pl.amount - item.amount, new_outgo13pl.amount
  end

  #
  # credit cardのitemを削除
  #
  def test_destroy_item_credit
    _login_and_change_month(2008,2)
    # dummy data
    xhr :post, :create, :item_name=>'test', :amount=>'1000', :action_year=>'2008', :action_month=>'2', :action_day=>'10',:from=>'4', :to=>'3', :year => 2008, :month => 2

    item = Item.find(:first, :conditions=>["name = 'test' and from_account_id = 4 and to_account_id = 3"])

    assert_not_nil item
    assert_not_nil item.child_id
    item_child = Item.find(item.child_id)
    assert_not_nil item_child

    xhr :delete, :destroy, :id=>item.id, :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :warning, Regexp.new(item.name)
#   assert_select_rjs :replace, "item_#{item.id}", ''
    assert_rjs :visual_effect, :fade, "item_#{item.id}", :duration => '0.3'
    assert_select_rjs :remove, "item_#{item.id}"
    assert_no_rjs :insert_html, :items

    assert_nil Item.find(:first, :conditions=>["id = ?", item.id])
    assert_nil Item.find(:first, :conditions=>["id = ?", item_child.id])
  end

  # 指定されたIDのitemが存在しない場合の処理
  def test_destroy_item_not_exist_id
    login
    xhr :delete, :destroy, :id => 20000, :year => Date.today.year, :month => Date.today.month
    assert_select_rjs :redirect, entries_path(Date.today.year, Date.today.month)
  end

  def test_destroy_adjustment_not_exist_id
    login
    xhr :delete, :destroy, :id => 20000, :year => Date.today.year, :month => Date.today.month
    assert_select_rjs :redirect, entries_path(Date.today.year, Date.today.month)
  end
  
  def test_destroy_adjustment
    _login_and_change_month(2008,2)

    # methodが不正
    get :destroy, :id=>items(:adjustment2).id, :year => 2008, :month => 2
    assert_redirected_to login_path
    post :destroy, :id=>items(:adjustment2).id, :year => 2008, :month => 2
    assert_redirected_to login_path

    #id を指定しない
    xhr :delete, :destroy, :id=>nil, :year => 2008, :month => 2
    assert_select_rjs :redirect, login_path

    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)
    init_bank_pl = monthly_profit_losses(:bank1200802)
    init_bank_pl = monthly_profit_losses(:bank1200802)
    init_unknown_pl = MonthlyProfitLoss.new
    init_unknown_pl.month = Date.new(2008,2)
    init_unknown_pl.account_id = -1
    init_unknown_pl.amount = 100
    init_unknown_pl.user_id = users(:user1).id
    init_unknown_pl.save!

    # 正常処理 (adj2を変更する。影響をうけるのはadj4のみ。mplには影響なし)
    xhr :delete, :destroy, :id=>items(:adjustment2).id, :year => 2008, :month => 2
    assert_no_rjs :redirect_to, login_path
    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_rjs :visual_effect, :fade, 'item_' + init_adj2.id.to_s, :duration => '0.3'
    assert_select_rjs :remove, 'item_' + init_adj2.id.to_s
    assert_select_rjs :replace, 'item_' + init_adj4.id.to_s
    assert_rjs :visual_effect, :highlight, 'item_' + init_adj4.id.to_s, :duration => HIGHLIGHT_DURATION
    assert_no_rjs :replace, 'item_' + init_adj6.id.to_s

    new_adj2 = Item.find_by_id(init_adj2.id)
    new_adj4 = Item.find(init_adj4.id)
    new_bank_pl = MonthlyProfitLoss.find(init_bank_pl.id)
    new_unknown_pl = MonthlyProfitLoss.find(init_unknown_pl.id)

    assert_nil new_adj2
    assert_equal init_adj4.amount + init_adj2.amount, new_adj4.amount
    assert_equal init_bank_pl.amount, new_bank_pl.amount
    assert_equal init_unknown_pl.amount, new_unknown_pl.amount
  end

  def test_destroy_adjustment_del_adj4
    _login_and_change_month(2008,2)

    # データの初期化
    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)
    init_bank_2_pl = monthly_profit_losses(:bank1200802)
    init_bank_3_pl = monthly_profit_losses(:bank1200803)
    init_unknown_2_pl = MonthlyProfitLoss.new
    init_unknown_2_pl.month = Date.new(2008,2)
    init_unknown_2_pl.account_id = -1
    init_unknown_2_pl.amount = 100
    init_unknown_2_pl.user_id = users(:user1).id
    init_unknown_2_pl.save!
    init_unknown_3_pl = MonthlyProfitLoss.new
    init_unknown_3_pl.month = Date.new(2008,3)
    init_unknown_3_pl.account_id = -1
    init_unknown_3_pl.amount = 311
    init_unknown_3_pl.user_id = users(:user1).id
    init_unknown_3_pl.save!

    # 正常処理 (adj4を削除。影響をうけるのはadj6と,200802, 200803のm_pl)
    xhr :delete, :destroy, :id=>items(:adjustment4).id, :year => 2008, :month => 2
    assert_no_rjs :redirect_to, login_path
    assert_select_rjs :remove, 'item_' + init_adj4.id.to_s
    assert_no_rjs :replace, 'item_' + init_adj2.id.to_s
    assert_no_rjs :replace, 'item_' + init_adj6.id.to_s

    new_adj2 = Item.find_by_id(init_adj2.id)
    new_adj4 = Item.find_by_id(init_adj4.id)
    new_adj6 = Item.find_by_id(init_adj6.id)
    new_bank_2_pl = MonthlyProfitLoss.find(init_bank_2_pl.id)
    new_bank_3_pl = MonthlyProfitLoss.find(init_bank_3_pl.id)
    new_unknown_2_pl = MonthlyProfitLoss.find(init_unknown_2_pl.id)
    new_unknown_3_pl = MonthlyProfitLoss.find(init_unknown_3_pl.id)

    assert_nil new_adj4
    assert_equal init_adj6.amount + init_adj4.amount, new_adj6.amount
    assert_equal init_bank_2_pl.amount - init_adj4.amount, new_bank_2_pl.amount
    assert_equal init_bank_3_pl.amount + init_adj4.amount, new_bank_3_pl.amount
    assert_equal init_unknown_2_pl.amount + init_adj4.amount, new_unknown_2_pl.amount
    assert_equal init_unknown_3_pl.amount - init_adj4.amount, new_unknown_3_pl.amount
  end


  def test_destroy_adjustment_del_adj6
    _login_and_change_month(2008,3)

    # データの初期化
    init_adj2 = Item.find(items(:adjustment2).id)
    init_adj4 = Item.find(items(:adjustment4).id)
    init_adj6 = Item.find(items(:adjustment6).id)
    init_bank_2_pl = monthly_profit_losses(:bank1200802)
    init_bank_3_pl = monthly_profit_losses(:bank1200803)
    init_unknown_2_pl = MonthlyProfitLoss.new
    init_unknown_2_pl.month = Date.new(2008,2)
    init_unknown_2_pl.account_id = -1
    init_unknown_2_pl.amount = 100
    init_unknown_2_pl.user_id = users(:user1).id
    init_unknown_2_pl.save!
    init_unknown_3_pl = MonthlyProfitLoss.new
    init_unknown_3_pl.month = Date.new(2008,3)
    init_unknown_3_pl.account_id = -1
    init_unknown_3_pl.amount = 311
    init_unknown_3_pl.user_id = users(:user1).id
    init_unknown_3_pl.save!


    # 正常処理 (adj6を削除。200803のm_pl)
    xhr :delete, :destroy, :id=>items(:adjustment6).id, :year => 2008, :month => 2
    assert_no_rjs :redirect_to, login_path #:controller => :login, :action => :login

    assert_no_rjs :redirect_to, login_path #:controller => :login, :action => :login
    assert_select_rjs :remove, 'item_' + init_adj6.id.to_s
    assert_no_rjs :replace, 'item_' + init_adj2.id.to_s
    assert_no_rjs :replace, 'item_' + init_adj4.id.to_s

    new_adj2 = Item.find_by_id(init_adj2.id)
    new_adj4 = Item.find_by_id(init_adj4.id)
    new_adj6 = Item.find_by_id(init_adj6.id)
    new_bank_2_pl = MonthlyProfitLoss.find(init_bank_2_pl.id)
    new_bank_3_pl = MonthlyProfitLoss.find(init_bank_3_pl.id)
    new_unknown_2_pl = MonthlyProfitLoss.find(init_unknown_2_pl.id)
    new_unknown_3_pl = MonthlyProfitLoss.find(init_unknown_3_pl.id)

    assert_nil new_adj6
    assert_equal init_adj2.amount, new_adj2.amount
    assert_equal init_adj4.amount, new_adj4.amount
    assert_equal init_bank_2_pl.amount, new_bank_2_pl.amount
    assert_equal init_bank_3_pl.amount - init_adj6.amount, new_bank_3_pl.amount
    assert_equal init_unknown_2_pl.amount, new_unknown_2_pl.amount
    assert_equal init_unknown_3_pl.amount + init_adj6.amount, new_unknown_3_pl.amount
  end

  ##########################
  # 編集画面
  ##########################
  def test_edit_with_no_login
    xhr :get, :edit
    assert_select_rjs :redirect, login_path
  end

  def test_edit_by_missing_params
    login

    xhr :get, :edit
    assert_select_rjs :redirect, entries_path(:year => Date.today.year, :month => Date.today.month)
  end
  
  def test_edit_with_entry_id
    login
    xhr :get, :edit, :id=>items(:item1).id.to_s

    assert_select_rjs :replace, 'item_' + items(:item1).id.to_s
    assert_template '_edit_item'
  end
  
  def test_edit_with_adjustment_id
    login
    xhr :get, :edit, :id=>items(:adjustment2).id.to_s

    assert_select_rjs :replace, 'item_' + items(:adjustment2).id.to_s
    assert_template '_edit_adjustment'
  end

  ######################
  # 残高調整の変更処理
  ######################
  def test_update_with_no_login
    xhr :put, :update, :entry_type => 'adjustment', :year => Date.today.year, :month => Date.today.month
    assert_select_rjs :redirect, login_path
  end

  def _login_and_change_month(year,month, current_action='items')
    login
    xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => current_action
  end
  
  def test_update_adjustment_with_no_id
    _login_and_change_month(2008,2)
    date = items(:adjustment2).action_date

    xhr :put, :update, :entry_type => 'adjustment', :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year => 2008, :month => 2
    assert_select_rjs :redirect, login_path
  end
  
  def test_update_adjustment_with_no_action_day
    _login_and_change_month(2008,2)
    date = items(:adjustment2).action_date
    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id.to_s, :action_year=>date.year, :action_month=>date.month, :action_amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year => 2008, :month => 2
    assert_select_rjs :replace_html, 'item_warning_' + items(:adjustment2).id.to_s, /date/i
    assert_rjs :visual_effect, :pulsate, 'item_warning_' + items(:adjustment2).id.to_s, :duration=>'1.0'
  end

  def test_update_adjustment_with_invalid_method
    _login_and_change_month(2008,2)
    date = items(:adjustment2).action_date
    post :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year => 2008, :month => 2
    
    assert_redirected_to login_path #:controller => :login, :action => :login
  end

  def test_update_adjustment_with_invalid_function
    _login_and_change_month(2008,2)
    date = items(:adjustment2).action_date

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'(20*30)/(10+1', :to=>items(:adjustment2).to_account_id, :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_no_rjs :replace, 'item_' + items(:adjustment2).id.to_s
    assert_no_rjs :replace, 'item_' + items(:adjustment4).id.to_s
    assert_select_rjs :replace_html, :warning
  end

  def test_update_adjustment_with_changing_only_amount
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    
    _login_and_change_month(2008,2)
    date = items(:adjustment2).action_date

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'(10+50)*200/4', :to=>items(:adjustment2).to_account_id, :year => 2008, :month => 2, :tag_list => 'hoge fuga'
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace, 'item_' + items(:adjustment2).id.to_s
    assert_select_rjs :replace, 'item_' + items(:adjustment4).id.to_s
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj2 = Item.find(items(:adjustment2).id)
    assert_equal 3000, new_adj2.adjustment_amount
    assert_equal old_adj2.action_date, new_adj2.action_date
    assert new_adj2.is_adjustment?

    assert_equal new_adj2.adjustment_amount - items(:adjustment2).adjustment_amount + old_adj2.amount, new_adj2.amount
    assert_equal old_adj4.amount + old_adj2.adjustment_amount - new_adj2.adjustment_amount, Item.find(items(:adjustment4).id).amount
    assert_equal old_adj6.amount, Item.find(items(:adjustment6).id).amount
    assert_equal old_m_pl_bank1_200802.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount
    assert_equal 'hoge fuga'.split(" ").sort.join(" "), new_adj2.tag_list
    tags = Tag.find_all_by_name('hoge')
    assert_equal 1, tags.size
    tags.each do |t|
      taggings = Tagging.find_all_by_tag_id(t.id)
      assert_equal 1, taggings.size
      taggings.each do |tgg|
        assert_equal users(:user1).id, tgg.user_id
        assert_equal 'Item', tgg.taggable_type
      end
    end
    
  end
  def test_update_adjustment_no_future_adjustment
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)
    login

    date = items(:adjustment6).action_date

    xhr :post, :change_month, :year=>date.year, :month=>date.month, :current_action=>'items'

    # 金額のみ変更
    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment6).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>items(:adjustment6).to_account_id, :year=>date.year, :month=>date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_no_rjs :replace, 'item_' + items(:adjustment2).id.to_s
    assert_no_rjs :replace, 'item_' + items(:adjustment4).id.to_s
    assert_select_rjs :replace, 'item_' + items(:adjustment6).id.to_s
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj2 = Item.find(items(:adjustment2).id)
    new_adj4 = Item.find(items(:adjustment4).id)
    new_adj6 = Item.find(items(:adjustment6).id)

    assert_equal old_adj6.action_date, new_adj6.action_date
    assert new_adj6.is_adjustment?

    assert_equal old_adj2.adjustment_amount, new_adj2.adjustment_amount
    assert_equal old_adj4.adjustment_amount, new_adj4.adjustment_amount
    assert_equal 3000, new_adj6.adjustment_amount
    assert_equal old_adj6.amount + (new_adj6.adjustment_amount - old_adj6.adjustment_amount), new_adj6.amount

    assert_equal old_m_pl_bank1_200803.amount + new_adj6.amount - old_adj6.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount
  end

  #
  # 日付に変更がなく、未来のadjが存在するが、当月ではない場合
  #
  def test_update_adjustment_if_future_adj_is_next_month
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)
    login
    date = old_adj4.action_date
    # 金額のみ変更
    xhr :put, :update, :entry_type => 'adjustment', :id=>old_adj4.id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>old_adj4.to_account_id, :year=>date.year, :month=>date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
#   assert_select_rjs :replace, 'item_' + items(:adjustment2).id.to_s
    assert_select_rjs :replace, 'item_' + items(:adjustment4).id.to_s
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj4 = Item.find(items(:adjustment4).id)
    new_m_pl_bank1_200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new_m_pl_bank1_200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal new_adj4.adjustment_amount - old_adj4.adjustment_amount + old_adj4.amount, new_adj4.amount
    assert_equal old_adj6.amount + old_adj4.amount - new_adj4.amount, Item.find(items(:adjustment6).id).amount

    assert_equal old_m_pl_bank1_200802.amount +
      (new_adj4.adjustment_amount - old_adj4.adjustment_amount), new_m_pl_bank1_200802.amount

    assert_equal old_m_pl_bank1_200803.amount -
      (new_adj4.adjustment_amount - old_adj4.adjustment_amount), new_m_pl_bank1_200803.amount
  end

  def test_update_adjustment_change_date
    # 日付、金額を変更(to_account_idは変更なし)
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)

    login

    date = items(:adjustment4).action_date - 1

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year=>date.year, :month=>date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj2 = Item.find(items(:adjustment2).id)
    assert_equal 3000, new_adj2.adjustment_amount
    assert_equal old_adj4.action_date - 1, new_adj2.action_date
    assert new_adj2.is_adjustment?

    assert_equal new_adj2.adjustment_amount - items(:adjustment2).adjustment_amount + old_adj2.amount, new_adj2.amount
    assert_equal old_adj4.amount + old_adj2.adjustment_amount - new_adj2.adjustment_amount, Item.find(items(:adjustment4).id).amount
    assert_equal old_adj6.amount, Item.find(items(:adjustment6).id).amount
    assert_equal old_m_pl_bank1_200802.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount
  end


  def test_update_adjustment_change_account_id
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)

    login

    xhr :post, :create, :entry_type => 'adjustment', :action_year=>old_adj4.action_date.year, :action_month=>old_adj4.action_date.month, :action_day=>old_adj4.action_date.day, :to=>13,:adjustment_amount => '1000', :year=>old_adj4.action_date.year, :month=>old_adj4.action_date.month
    old_adj_other = Item.find(:first, :conditions=>["action_date = ? and to_account_id = 13 and is_adjustment = ?", old_adj4.action_date, true])
    assert_not_nil old_adj_other
    date = old_adj2.action_date

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>old_adj_other.to_account_id, :year => date.year, :month => date.month

    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, "items", ''
    assert_select_rjs :insert_html, :bottom, 'items'
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'
  end

  def test_update_adjustment_change_date_to_next_month
    # 日付、金額を変更
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)

    login

    date = items(:adjustment6).action_date - 1

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year => date.year, :month => date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj2 = Item.find(items(:adjustment2).id)
    assert_equal 3000, new_adj2.adjustment_amount
    assert_equal old_adj6.action_date - 1, new_adj2.action_date
    assert new_adj2.is_adjustment?

    assert_equal new_adj2.adjustment_amount - (13900 - 22000), new_adj2.amount
    assert_equal old_adj4.amount + old_adj2.amount, Item.find(items(:adjustment4).id).amount
    assert_equal old_adj6.amount - new_adj2.amount, Item.find(items(:adjustment6).id).amount
    assert_equal old_m_pl_bank1_200802.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount
    assert_equal old_m_pl_bank1_200803.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount
  end

  def test_update_adjustment_change_date_to_next_month_no_future_adj
    # 日付、金額を変更
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)
    old_m_pl_bank1_200803 = monthly_profit_losses(:bank1200803)

    login

    date = items(:adjustment6).action_date + 1

    xhr :put, :update, :entry_type => 'adjustment', :id=>items(:adjustment2).id, :action_year=>date.year, :action_month=>date.month, :action_day=>date.day, :adjustment_amount=>'3,000', :to=>items(:adjustment2).to_account_id, :year => date.year, :month => date.month
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + date.strftime("%Y/%m/%d") + ' ' + 'Adjustment' + ' ' +
      CommonUtil.separate_by_comma(3000) + 'yen'

    new_adj2 = Item.find(items(:adjustment2).id)
    assert_equal 3000, new_adj2.adjustment_amount
    assert_equal old_adj6.action_date + 1, new_adj2.action_date
    assert new_adj2.is_adjustment?

    assert_equal new_adj2.adjustment_amount - (12900 - 22000), new_adj2.amount
    assert_equal old_adj4.amount + old_adj2.amount, Item.find(items(:adjustment4).id).amount
    assert_equal old_adj6.amount, Item.find(items(:adjustment6).id).amount
    assert_equal old_m_pl_bank1_200802.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount
    assert_equal old_m_pl_bank1_200803.amount + new_adj2.amount, MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount
  end



  def test_update_item_no_login
    xhr :put, :update
    assert_select_rjs :redirect, login_path #:controller=>:login,:action=>:login
  end
  
  def test_update_item
    _login_and_change_month(2008, 2, 'index')

    old_item1 = items(:item1)
    old_item11 = items(:item11)
    old_adj2 = items(:adjustment2)
    old_adj4 = items(:adjustment4)
    old_adj6 = items(:adjustment6)
    old_pl200712 = monthly_profit_losses(:bank1200712)
    old_pl200801 = monthly_profit_losses(:bank1200801)
    old_pl200802 = monthly_profit_losses(:bank1200802)
    old_pl200803 = monthly_profit_losses(:bank1200803)
    old_pl200712_out = monthly_profit_losses(:outgo3200712)
    old_pl200801_out = monthly_profit_losses(:outgo3200801)
    old_pl200802_out = monthly_profit_losses(:outgo3200802)
    #old_pl200803_out = monthly_profit_losses(:outgo3200803)  # nil 存在しない
    old_pl200803_out = nil

    today = Date.today
    # params missing
    xhr :put, :update, :year => 2008, :month => 2
    assert_select_rjs :redirect, login_path #:controller=>:login,:action=>:login

    xhr :put, :update, :id=>items(:item1).id.to_s, :year => 2008, :month => 2
    assert_select_rjs :replace_html, 'item_warning_' + items(:item1).id.to_s
    assert_rjs :visual_effect, :pulsate, 'item_warning_' + items(:item1).id.to_s, :duration=>'1.0'

    # methodが不正
    post :update, :id=>items(:item11).id.to_s, :item_name=>'テスト11', :action_year=>old_item11.action_date.year.to_s, :action_month=>old_item11.action_date.month.to_s, :action_day=>old_item11.action_date.day.to_s, :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
    assert_redirected_to login_path

    # regular (action_date not change)
    xhr :put, :update, :id=>items(:item11).id.to_s, :item_name=>'テスト11', :action_year=>old_item11.action_date.year.to_s, :action_month=>old_item11.action_date.month.to_s, :action_day=>old_item11.action_date.day.to_s, :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status, Regexp.new(account_status_path)
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace, 'item_' + items(:item11).id.to_s, Regexp.new('100,000')
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully. ' + Date.new(old_item11.action_date.year,old_item11.action_date.month,old_item11.action_date.day).strftime("%Y/%m/%d") + ' ' + 'テスト11' + ' ' + CommonUtil.separate_by_comma(100000) + 'yen'
    #assert_select_rjs :visual_effect, :highlight, 'item_' + items(:item11).id.to_s, :duration=>'1.0'


    # regular (action_date's month is not changed and future and same month's adjustment exists)
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト10', :action_year=>old_item1.action_date.year.to_s, :action_month=>old_item1.action_date.month.to_s, :action_day=>'18', :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + Date.new(old_item1.action_date.year,old_item1.action_date.month,18).strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(100000) + 'yen'
    #assert_select_rjs :visual_effect, :highlight, 'item_' + items(:item1).id.to_s, :duration=>'1.0'

    # データの整合性チェック
    new1_item1 = Item.find(items(:item1).id)
    new1_adj2 = Item.find(items(:adjustment2).id)
    new1_adj4 = Item.find(items(:adjustment4).id)
    new1_adj6 = Item.find(items(:adjustment6).id)
    new1_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new1_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new1_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new1_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
    new1_pl200712_out = MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200712).id)
    new1_pl200801_out = MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200801).id)
    new1_pl200802_out = MonthlyProfitLoss.find(monthly_profit_losses(:outgo3200802).id)
    new1_pl200803_out = MonthlyProfitLoss.find(:first,
                         :conditions=>["user_id = ? and account_id = ? and month = ?",
                                 users(:user1).id, accounts(:outgo3).id,
                                 Date.new(2008,3,1)])  # nil 存在しないはず


    assert_equal 'テスト10', new1_item1.name
    assert_equal Date.new(old_item1.action_date.year,old_item1.action_date.month,18), new1_item1.action_date
    assert_equal 100000, new1_item1.amount
    assert_equal accounts(:bank1).id, new1_item1.from_account_id
    assert_equal accounts(:outgo3).id, new1_item1.to_account_id
    assert (not new1_item1.confirmation_required?)

    assert_equal old_adj2.amount - old_item1.amount + new1_item1.amount, new1_adj2.amount
    assert_equal old_adj4.amount, new1_adj4.amount
    assert_equal old_adj6.amount, new1_adj6.amount
    assert_equal old_pl200712.amount, new1_pl200712.amount
    assert_equal old_pl200801.amount, new1_pl200801.amount
    assert_equal old_pl200802.amount, new1_pl200802.amount
    assert_equal old_pl200803.amount, new1_pl200803.amount
    assert_equal old_pl200712_out.amount, new1_pl200712_out.amount
    assert_equal old_pl200801_out.amount, new1_pl200801_out.amount
    assert_equal old_pl200802_out.amount - old_item1.amount + new1_item1.amount, new1_pl200802_out.amount
    assert_nil new1_pl200803_out


    # regular (confirmation_required == true)
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト10', :action_year=>old_item1.action_date.year.to_s, :action_month=>old_item1.action_date.month.to_s, :action_day=>'18', :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :confirmation_required => 'true', :year => 2008, :month => 2
    item_confirm_required = Item.find_by_id(items(:item1).id)
    assert item_confirm_required.confirmation_required?

    # regular (タグにゅうりょく)
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト10', :action_year=>old_item1.action_date.year.to_s, :action_month=>old_item1.action_date.month.to_s, :action_day=>'18', :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :confirmation_required => 'true', :tag_list => 'hoge fuga', :year => 2008, :month => 2
    item_confirm_required = Item.find_by_id(items(:item1).id)
    assert item_confirm_required.confirmation_required?
    assert_equal 'hoge fuga'.split(" ").sort.join(" "), item_confirm_required.tag_list
    tags = Tag.find_all_by_name('hoge')
    assert_equal 1, tags.size
    tags.each do |t|
      taggings = Tagging.find_all_by_tag_id(t.id)
      assert_equal 1, taggings.size
      taggings.each do |tgg|
        assert_equal users(:user1).id, tgg.user_id
        assert_equal 'Item', tgg.taggable_type
      end
    end

    # regular (amountが数式)
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト10', :action_year=>old_item1.action_date.year.to_s, :action_month=>old_item1.action_date.month.to_s, :action_day=>'18', :amount=>"(100-20)*1.007", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :confirmation_required => 'true', :year => 2008, :month => 2
    item_calc = Item.find_by_id(items(:item1).id)
    assert_equal (80*1.007).to_i, item_calc.amount


    # 不正 (amountが不正な式)
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト10', :action_year => old_item1.action_date.year.to_s, :action_month => old_item1.action_date.month.to_s, :action_day => '18', :amount=>"(100-20)*(10", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :confirmation_required => 'true', :year => 2008, :month => 2
    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_no_rjs :replace_html, :items, ''
    assert_no_rjs :insert_html, :bottom, :items
    assert_select_rjs :replace_html, 'item_warning_1'
    assert_rjs :visual_effect, :pulsate, 'item_warning_1', :duration => '1.0'
  end

  # regular (action_date's month is not changed, but day is changed from before-adj to after-adj
  # and future-same month's adjustment DOES NOT exists)
  def test_update_item_from_before_adj2_to_after_adj4
    login

    new1_item1 = items(:item1)
    new1_adj2 = items(:adjustment2)
    new1_adj4 = items(:adjustment4)
    new1_adj6 = items(:adjustment6)
    new1_pl200712 = monthly_profit_losses(:bank1200712)
    new1_pl200801 = monthly_profit_losses(:bank1200801)
    new1_pl200802 = monthly_profit_losses(:bank1200802)
    new1_pl200803 = monthly_profit_losses(:bank1200803)
    date = new1_adj4.action_date + 1
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト20', :action_year=>date.year.to_s, :action_month=>date.month.to_s, :action_day=>date.day.to_s, :amount=>"20000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => items(:item1).action_date.year, :month => items(:item1).action_date.month

    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status, Regexp.new(confirmation_status_path)
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items  # remains_list
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' +  Date.new(date.year,date.month,date.day).strftime("%Y/%m/%d") + ' ' + 'テスト20' + ' ' + CommonUtil.separate_by_comma(20000) + 'yen'
#   assert_select_rjs :visual_effect, :highlight, 'item_' + items(:item1).id.to_s, :duration=>'1.0'

    # データの整合性チェック
    new2_item1 = Item.find(items(:item1).id)
    new2_adj2 = Item.find(items(:adjustment2).id)
    new2_adj4 = Item.find(items(:adjustment4).id)
    new2_adj6 = Item.find(items(:adjustment6).id)
    new2_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new2_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new2_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new2_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal 'テスト20', new2_item1.name
    assert_equal Date.new(date.year,date.month,date.day), new2_item1.action_date
    assert_equal 20000, new2_item1.amount
    assert_equal accounts(:bank1).id, new2_item1.from_account_id
    assert_equal accounts(:outgo3).id, new2_item1.to_account_id

    assert_equal new1_adj2.amount - new1_item1.amount, new2_adj2.amount
    assert_equal new1_adj4.amount, new2_adj4.amount
    assert_equal new1_adj6.amount + new2_item1.amount, new2_adj6.amount  # this is the different month

    assert_equal new1_pl200712.amount, new2_pl200712.amount
    assert_equal new1_pl200801.amount, new2_pl200801.amount
    assert_equal new1_pl200802.amount - new2_item1.amount, new2_pl200802.amount
    assert_equal new1_pl200803.amount + new2_item1.amount , new2_pl200803.amount
  end

  # regular (action_date's month, day are not changed
  # and future-same month's adjustment DOES NOT exists)
  def test_update_item_after_adj4_same_month
    _login_and_change_month(2008,2)

    old_item5 = Item.find(items(:item5).id)
    new2_item1 = Item.find(items(:item1).id)
    new2_adj2 = Item.find(items(:adjustment2).id)
    new2_adj4 = Item.find(items(:adjustment4).id)
    new2_adj6 = Item.find(items(:adjustment6).id)
    new2_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new2_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new2_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new2_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    xhr :put, :update, :id=>items(:item5).id, :item_name=>'テスト30', :action_year=>old_item5.action_date.year.to_s, :action_month=>old_item5.action_date.month.to_s, :action_day=>old_item5.action_date.day.to_s, :amount=>"20000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => 2008, :month => 2

    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status
    assert_select_rjs :replace, 'item_' + items(:item5).id.to_s
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + old_item5.action_date.strftime("%Y/%m/%d") + ' ' + 'テスト30' + ' ' + CommonUtil.separate_by_comma(20000) + 'yen'
#   assert_select_rjs :visual_effect, :highlight, 'item_' + items(:item5).id.to_s, :duration=>'1.0'


    # データの整合性チェック
    new3_item1 = Item.find(items(:item1).id)
    new3_adj2 = Item.find(items(:adjustment2).id)
    new3_adj4 = Item.find(items(:adjustment4).id)
    new3_item5 = Item.find(items(:item5).id)
    new3_adj6 = Item.find(items(:adjustment6).id)
    new3_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new3_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new3_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new3_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal 'テスト30', new3_item5.name
    assert_equal old_item5.action_date, new3_item5.action_date
    assert_equal 20000, new3_item5.amount
    assert_equal accounts(:bank1).id, new3_item5.from_account_id
    assert_equal accounts(:outgo3).id, new3_item1.to_account_id

    assert_equal new2_adj2.amount, new3_adj2.amount
    assert_equal new2_adj4.amount, new3_adj4.amount
    assert_equal new2_adj6.amount - old_item5.amount + new3_item5.amount, new3_adj6.amount
    assert_equal new2_pl200712.amount, new3_pl200712.amount
    assert_equal new2_pl200801.amount, new3_pl200801.amount
    assert_equal new2_pl200802.amount + old_item5.amount - new3_item5.amount, new3_pl200802.amount
    assert_equal new2_pl200803.amount - old_item5.amount + new3_item5.amount, new3_pl200803.amount
  end

  # adj2 adj4の間にあるitemを変更し adj6の手前に日付にする(金額も変更)
  def test_update_item_from_adj2_adj4_to_before_adj6
    login

    new3_item3 = items(:item3)
    new3_item1 = items(:item1)
    new3_adj2 = items(:adjustment2)
    new3_adj4 = items(:adjustment4)
    new3_item5 = items(:item5)
    new3_adj6 = items(:adjustment6)
    new3_pl200712 = monthly_profit_losses(:bank1200712)
    new3_pl200801 = monthly_profit_losses(:bank1200801)
    new3_pl200802 = monthly_profit_losses(:bank1200802)
    new3_pl200803 = monthly_profit_losses(:bank1200803)

    date = new3_adj6.action_date - 1
    xhr :put, :update, :id=>items(:item3).id, :item_name=>'テスト50', :action_year=>date.year.to_s, :action_month=>date.month.to_s, :action_day=>date.day.to_s, :amount=>"300", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => items(:item3).action_date.year, :month => items(:item3).action_date.month


    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items  # remains_list
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' +  Date.new(date.year,date.month,date.day).strftime("%Y/%m/%d") + ' ' + 'テスト50' + ' ' + CommonUtil.separate_by_comma(300) + 'yen'

    # データの整合性チェック
    new4_item3 = Item.find(items(:item3).id)
    new4_adj2 = Item.find(items(:adjustment2).id)
    new4_adj4 = Item.find(items(:adjustment4).id)
    new4_adj6 = Item.find(items(:adjustment6).id)
    new4_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new4_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new4_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new4_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal 'テスト50', new4_item3.name
    assert_equal Date.new(date.year,date.month,date.day), new4_item3.action_date
    assert_equal 300, new4_item3.amount
    assert_equal accounts(:bank1).id, new4_item3.from_account_id
    assert_equal accounts(:outgo3).id, new4_item3.to_account_id

    assert_equal new3_adj2.amount, new4_adj2.amount
    assert_equal new3_adj4.amount - new3_item3.amount, new4_adj4.amount
    assert_equal new3_adj6.amount + new4_item3.amount, new4_adj6.amount

    assert_equal new3_pl200712.amount, new4_pl200712.amount
    assert_equal new3_pl200801.amount, new4_pl200801.amount
    assert_equal new3_pl200802.amount, new4_pl200802.amount
    assert_equal new3_pl200803.amount, new4_pl200803.amount
  end

  # item1をadj6(次月のadjのうしろ)に移動(価格を変更)
  def test_update_item_from_before_adj2_to_after_adj6
    login

    new3_item1 = items(:item1)
    new3_adj2 = items(:adjustment2)
    new3_adj4 = items(:adjustment4)
    new3_item5 = items(:item5)
    new3_adj6 = items(:adjustment6)
    new3_pl200712 = monthly_profit_losses(:bank1200712)
    new3_pl200801 = monthly_profit_losses(:bank1200801)
    new3_pl200802 = monthly_profit_losses(:bank1200802)
    new3_pl200803 = monthly_profit_losses(:bank1200803)

    date = new3_adj6.action_date + 1
    xhr :put, :update, :id=>items(:item1).id, :item_name=>'テスト50', :action_year=>date.year.to_s, :action_month=>date.month.to_s, :action_day=>date.day.to_s, :amount=>"300", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => items(:item1).action_date.year, :month => items(:item1).action_date.month


    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items  # remains_list
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' +  Date.new(date.year,date.month,date.day).strftime("%Y/%m/%d") + ' ' + 'テスト50' + ' ' + CommonUtil.separate_by_comma(300) + 'yen'
#   assert_select_rjs :visual_effect, :highlight, 'item_' + items(:item1).id.to_s, :duration=>'1.0'

    # データの整合性チェック
    new4_item1 = Item.find(items(:item1).id)
    new4_adj2 = Item.find(items(:adjustment2).id)
    new4_adj4 = Item.find(items(:adjustment4).id)
    new4_adj6 = Item.find(items(:adjustment6).id)
    new4_pl200712 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id)
    new4_pl200801 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id)
    new4_pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
    new4_pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)

    assert_equal 'テスト50', new4_item1.name
    assert_equal Date.new(date.year,date.month,date.day), new4_item1.action_date
    assert_equal 300, new4_item1.amount
    assert_equal accounts(:bank1).id, new4_item1.from_account_id
    assert_equal accounts(:outgo3).id, new4_item1.to_account_id

    assert_equal new3_adj2.amount - new3_item1.amount, new4_adj2.amount
    assert_equal new3_adj4.amount, new4_adj4.amount
    assert_equal new3_adj6.amount, new4_adj6.amount

    assert_equal new3_pl200712.amount, new4_pl200712.amount
    assert_equal new3_pl200801.amount, new4_pl200801.amount
    assert_equal new3_pl200802.amount, new4_pl200802.amount
    assert_equal new3_pl200803.amount - new4_item1.amount , new4_pl200803.amount
  end

  ###############################
  # クレジットカードの変更処理
  ###############################
  def test_update_item_credit_item
    # 前処理
    _login_and_change_month(2008,2)
    xhr :post, :create, :action_year=>'2008', :action_month=>'2', :action_day=>'10', :item_name=>'テスト10', :amount=>'10,000', :from=>accounts(:credit4).id, :to=>accounts(:outgo3).id,
    :year => 2008,
    :month => 2
    
    init_credit_item = Item.find(:first, :conditions=>["action_date = ? and from_account_id = ? and to_account_id = ?",
                             Date.new(2008,2,10),
                             accounts(:credit4).id,
                             accounts(:outgo3).id])
    assert_not_nil init_credit_item
    init_payment_item = Item.find(init_credit_item.child_id)
    date = init_credit_item.action_date
    assert_equal 10000, init_credit_item.amount
    
    xhr :put, :update, :id=>init_credit_item.id, :item_name=>'テスト10', :action_year=>date.year.to_s, :action_month=>date.month.to_s, :action_day=>date.day.to_s, :amount=>"20000", :from=>accounts(:credit4).id.to_s, :to=>accounts(:outgo3).id.to_s, :year => init_credit_item.action_date.year, :month => init_credit_item.action_date.month

    new_credit_item = Item.find(init_credit_item.id)
    new_payment_item = Item.find(new_credit_item.child_id)
    assert_no_rjs :replace_html, :account_status
    assert_no_rjs :replace_html, :confirmation_status
    assert_select_rjs :replace, 'item_' + init_credit_item.id.to_s
    assert_select_rjs :replace_html, :warning, 'Item was changed successfully.' + ' ' + init_credit_item.action_date.strftime("%Y/%m/%d") + ' ' + 'テスト10' + ' ' + CommonUtil.separate_by_comma(20000) + 'yen'
    assert_no_rjs :replace_html, 'item_' + init_payment_item.id.to_s
    assert_no_rjs :replace_html, 'item_' + new_payment_item.id.to_s
    assert_equal 20000, new_credit_item.amount
    assert_not_equal new_payment_item.id, init_payment_item.id
    assert_equal 20000, new_payment_item.amount
  end

  ##############################
  # show
  ##############################
  def test_show
    _login_and_change_month(2008,2)
    
    xhr :get, :show, :id => 1
    assert_response :success
    assert_select_rjs :replace, 'item_1'
  end

  def test_show_no_login
    xhr :get, :show, :id => 1
    assert_select_rjs :redirect, login_path
  end
  
  def test_show_no_id
    _login_and_change_month(2008,2)
    xhr :get, :show
    assert_select_rjs :redirect, current_entries_path
  end
  
  def test_show_with_not_existent_id
    _login_and_change_month(2008,2)
    xhr :get, :show, :id => 3413431
    assert_select_rjs :redirect, current_entries_path
  end
  
  def test_show_remaining_items_with_no_login
    xhr :get, :index, :remaining => true
    assert_select_rjs :redirect, login_path
  end
  
  def test_show_remaining_items_with_missing_params
    _login_and_change_month(2008,2)
    xhr :get, :index, :remaining => true
    assert_select_rjs :redirect, current_entries_path
  end
  
  def _prepare_regular_entries_with_tag
    # データの用意
    50.times do |i|
      create_entry  :action_year=>2008, :action_month=>2, :action_day=>3,  :item_name=>'テスト-' + i.to_s, :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :tag_list => 'abc def', :year => 2008, :month => 2
    end
    assert Item.count(:conditions => ["action_date = ?", Date.new(2008,2,3)]) >= 50
  end
  
  def test_show_remaining_items
    _login_and_change_month(2008,2)
    _prepare_regular_entries_with_tag
    xhr :get, :index, :remaining => true, :year => 2008, :month => 2
    
    assert_rjs :visual_effect, :fade, :remains, :duration => '0.3'
    assert_select_rjs :remove, :remains
    assert_select_rjs :insert_html, :bottom, :items
    assert_not_nil assigns(:separated_accounts)
  end
  def test_show_remaining_items_with_tag
    _login_and_change_month(2008,2)
    _prepare_regular_entries_with_tag
    xhr :get, :index, :remaining => true, :year => 2008, :month => 2, :tag => 'abc'
    
    assert_rjs :visual_effect, :fade, :remains, :duration => '0.3'
    assert_select_rjs :remove, :remains
    assert_select_rjs :insert_html, :bottom, :items
    assert_not_nil assigns(:separated_accounts)
  end

  #
  # フィルター変更処理
  #
  def test_index_change_account_filter_with_no_login
    xhr :get, :index, :filter_account_id => accounts(:bank1).id, :year => '2008', :month => '2'
    assert_select_rjs :redirect, login_path
  end    

  def test_index_change_account_filter
    login
    xhr :get, :index, :filter_account_id => accounts(:bank1).id, :year => '2008', :month => '2'
    assert_select_rjs :replace_html, :items, ''
    assert_select_rjs :insert_html, :bottom, :items
    assert_not_nil assigns(:items)
    assert_equal accounts(:bank1).id, session[:filter_account_id]
  end

  def test_index_with_tag
    login
    xhr :put, :update, :id=>items(:item11).id.to_s, :item_name=>'テスト11', :action_year=>items(:item11).action_date.year.to_s, :action_month=>items(:item11).action_date.month.to_s, :action_day=>items(:item11).action_date.day.to_s, :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :tag_list => 'abc def', :year => items(:item11).action_date.year, :month => items(:item11).action_date.month
    a = ['abc', 'def']
    Item.find(items(:item11).id).tags.each do |tag|
      assert a.include?(tag.name)
    end
    assert_equal 2, Item.find(items(:item11).id).tags.size
    
    get :index, :tag => 'abc'
    assert_response :success
    assert_not_nil assigns(:items)
    assert_equal 1, assigns(:items).size
    assert_equal 'abc', assigns(:tag)
    assert_template 'index_with_tag'
  end
  
  def test_index_with_mark
    login
    xhr :put, :update, :id=>items(:item11).id.to_s, :item_name=>'テスト11', :action_year=>items(:item11).action_date.year.to_s, :action_month=>items(:item11).action_date.month.to_s, :action_day=>items(:item11).action_date.day.to_s, :amount=>"100000", :from=>accounts(:bank1).id.to_s, :to=>accounts(:outgo3).id.to_s, :confirmation_required => '1', :year => items(:item11).action_date.year, :month => items(:item11).action_date.month
    orig_item = Item.find(items(:item11).id)
    assert orig_item.confirmation_required?

    get :index, :mark => 'confirmation_required'
    assert_response :success
    assert_not_nil assigns(:items)
    assert_equal Item.count(:conditions => { :confirmation_required => true}), assigns(:items).size
    assigns(:items).each do |it|
      assert it.confirmation_required?
    end
    assert_equal 'confirmation_required', assigns(:mark)
    assert_template 'index_with_mark'
  end
end
