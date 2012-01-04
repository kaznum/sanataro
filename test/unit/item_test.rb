# -*- coding: utf-8 -*-
require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :items, :users, :accounts, :monthly_profit_losses

  def test_create
    item = Item.new
#    item.user_id = 1
    item.user = users(:user1)
    item.name = 'aaaaa'
    item.year = 2008
    item.month = 10
    item.day = 17
#   item.set_action_date 2008, 10, 17
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = 10000
    item.confirmation_required = true
    item.tag_list = 'hoge fuga'
    assert item.save!
    new_item  = Item.find_by_id(item.id)
    assert_equal Date.new(2008,10,17), new_item.action_date
    assert_not_nil new_item.created_at
    assert (not new_item.is_adjustment?)
    assert new_item.confirmation_required?
#    assert_equal 'hello', new_item.memo
    new_item.confirmation_required = false
    assert new_item.save
    new2_item  = Item.find_by_id(new_item.id)
    assert (not new2_item.confirmation_required?)
  end
  
  def test_retrieve_month
    item = Item.new
    item.month = nil
    assert_nil item.month
  end

  def test_create_name_nil
    item = Item.new
#    item.user_id = 1
    item.user = users(:user1)
    item.name = nil
    item.year = 2008
    item.month = 10
    item.day = 17
#   item.set_action_date 2008, 10, 17
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = 10000
    assert (not item.save)
    assert item.errors[:name].any?
  end

  def test_create_amount_nil
    item = Item.new
    item.user = users(:user1)
    item.name = 'aaaa'
    item.year = 2008
    item.month = 10
    item.day = 17
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = nil
    assert (not item.save)
    assert item.errors[:amount].any?
  end

  def test_create_account_id_nil
    item = Item.new
    item.user = users(:user1)
    item.name = 'aaaa'
    item.year = 2008
    item.month = 10
    item.day = 17
    item.amount = 100000

    # from_id
    item.from_account_id = nil
    item.to_account_id = 2
    assert (not item.save)

    # to_id
    item.from_account_id = 1
    item.to_account_id = nil
    assert (not item.save)

  end


  def test_create_action_date_illegal
    item = Item.new
    item.user = users(:user1)
    item.name = 'aaaaa'
    item.year = 2008
    item.month = 2
    item.day = 30
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = 10000
    assert (not item.save)
    assert item.errors[:action_date].any?
  end
  def test_action_date_too_past
    item = Item.new
    # too old
    item.year = 2005
    item.month = 12
    item.day = 31
    assert (not item.save)
    assert item.errors[:action_date].any?
  end
  
  def test_action_date_too_future
    item = Item.new
    # too future
    too_future_date = Date.today + 366 * 2
    item.year = too_future_date.year
    item.month = too_future_date.month
    item.day = too_future_date.day
    assert (not item.save)
    assert item.errors[:action_date].any?
  end

  def test_getting_date
    item1 = Item.find(1)
    assert_equal 2008, item1.year
    assert_equal 2, item1.month
    assert_equal 15, item1.day

    item1.year = nil
    assert_nil item1.year
    assert_nil item1.month
    assert_nil item1.day
    assert_nil item1.action_date

    item1.year = 2008
    item1.month = 2
    item1.day = 15

    item1.month = nil
    assert_nil item1.year
    assert_nil item1.month
    assert_nil item1.day
    assert_nil item1.action_date

    item1.year = 2008
    item1.month = 2
    item1.day = 15

    item1.day = nil
    assert_nil item1.year
    assert_nil item1.month
    assert_nil item1.day
    assert_nil item1.action_date
    item1.year = 2008
    item1.month = 2
    item1.day = 15
    
    assert_equal item1.action_date, Date.new(2008,2,15)
    assert_equal item1.year, 2008
    assert_equal item1.month, 2
    assert_equal item1.day, 15
  end

  def test_adjust_future_balance_a
    item1 = Item.find(1)
    adj2 = Item.find(2)
    item3 = Item.find(3)
    adj4 = Item.find(4)
    plbank1 = monthly_profit_losses(:bank1200802)

    # item1の金額を+100した場合、adj2のamountが+100になる
    # adj4は変化しない
    assert_nothing_thrown do
      User.find(item1.user_id).items.adjust_future_balance(User.find(item1.user_id), item1.from_account_id, 100, item1.action_date, item1.id)
    end

    adj2_chngd = Item.find(2)
    adj4_chngd = Item.find(4)
    plbank1_chngd = MonthlyProfitLoss.find(plbank1.id)

    assert_equal adj2.amount + 100, adj2_chngd.amount
    assert_equal adj2.adjustment_amount, adj2_chngd.adjustment_amount

    assert_equal adj4.amount, adj4_chngd.amount
    assert_equal adj4.adjustment_amount, adj4_chngd.adjustment_amount
    assert_equal plbank1.amount + 100, plbank1_chngd.amount
  end
  
  #
  # item_idを指定しない。
  #
  def test_adjust_future_balance_a_2
    item1 = Item.find(1)
    adj2 = Item.find(2)
    item3 = Item.find(3)
    adj4 = Item.find(4)
    plbank1 = monthly_profit_losses(:bank1200802)

    # item1の金額を+100した場合、adj2のamountが+100になる
    # adj4は変化しない
    assert_nothing_thrown do
      User.find(item1.user_id).items.adjust_future_balance(User.find(item1.user_id), item1.from_account_id, 100, item1.action_date)
    end

    adj2_chngd = Item.find(2)
    adj4_chngd = Item.find(4)
    plbank1_chngd = MonthlyProfitLoss.find(plbank1.id)

    assert_equal adj2.amount + 100, adj2_chngd.amount
    assert_equal adj2.adjustment_amount, adj2_chngd.adjustment_amount

    assert_equal adj4.amount, adj4_chngd.amount
    assert_equal adj4.adjustment_amount, adj4_chngd.adjustment_amount
    assert_equal plbank1.amount + 100, plbank1_chngd.amount
  end

  def test_adjust_future_balance_b
    # item3の金額を+100した場合、adj4のamountが+100になる
    # adj2は変化しない
    item1 = Item.find(1)
    adj2 = Item.find(2)
    item3 = Item.find(3)
    adj4 = Item.find(4)
    plbank1 = monthly_profit_losses(:bank1200802)

    assert_nothing_thrown do
      User.find(item3.user_id).items.adjust_future_balance(User.find(item3.user_id), item3.from_account_id, 100, item3.action_date, item3.id)
    end

    adj2_chngd = Item.find(2)
    adj4_chngd = Item.find(4)

    assert_equal adj2.amount, adj2_chngd.amount
    assert_equal adj2.adjustment_amount, adj2_chngd.adjustment_amount

    assert_equal adj4.amount + 100, adj4_chngd.amount
    assert_equal adj4.adjustment_amount, adj4_chngd.adjustment_amount

    plbank1_chngd = MonthlyProfitLoss.find(plbank1.id)
    assert_equal plbank1.amount + 100, plbank1_chngd.amount

  end

  #
  # adjustmentのitemとaction_dateが同一のitemを追加した場合、
  # 同一の日のadjustmentは影響されないが、action_dateが大きいadjustmentは影響される。
  #
  def test_adjust_future_balance_c
    # item3の金額を+100した場合、adj4のamountが+100になる
    # adj2は変化しない
    item1 = Item.find(1)
    adj2 = Item.find(2)
    item3 = Item.find(3)
    adj4 = Item.find(4)
    plbank1 = monthly_profit_losses(:bank1200802)

    item = Item.new
    item.id = 105
#    item.user_id = 1
    item.user = users(:user1)
    item.name = 'aaaaa'
    item.year = adj2.action_date.year
    item.month = adj2.action_date.month
    item.day = adj2.action_date.day
    #item.set_action_date adj2.action_date.year, adj2.action_date.month, adj2.action_date.day
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = 10000
    item.save

    assert_nothing_thrown do
      User.find(item.user_id).items.adjust_future_balance(User.find(item.user_id), item.from_account_id, 10000, item.action_date, item.id)
    end

    adj2_chngd = Item.find(2)
    adj4_chngd = Item.find(4)

    assert_equal adj2.amount, adj2_chngd.amount
    assert_equal adj2.adjustment_amount, adj2_chngd.adjustment_amount

    assert_equal adj4.amount + 10000, adj4_chngd.amount
    assert_equal adj4.adjustment_amount, adj4_chngd.adjustment_amount

    plbank1_chngd = MonthlyProfitLoss.find(plbank1.id)
    assert_equal plbank1.amount + 10000, plbank1_chngd.amount

  end

  #
  # item5を変更すると、adj6(翌月のadjustment item)に影響がでる。同時に
  # monthly_profit_lossも翌月に変更が加わる
  #
  def test_adjust_future_balance_d
    # item3の金額を+100した場合、adj4のamountが+100になる
    # adj2は変化しない
    item1 = Item.find(1)
    adj2 = Item.find(2)
    item3 = Item.find(3)
    adj4 = Item.find(4)
    adj6 = items(:adjustment6)
    plbank1 = monthly_profit_losses(:bank1200802)
    plbank1_03 = monthly_profit_losses(:bank1200803)

    item = Item.new
    item.id = 105
#    item.user_id = 1
    item.user = users(:user1)
    item.name = 'aaaaa'
    item.year = adj6.action_date.year
    item.month = adj6.action_date.month
    item.day = adj6.action_date.day - 1
    #item.set_action_date adj2.action_date.year, adj2.action_date.month, adj2.action_date.day
    item.from_account_id = 1
    item.to_account_id = 2
    item.amount = 200
    item.save

    assert_nothing_thrown do
      Item.adjust_future_balance(User.find(item.user_id), item.from_account_id, 200, item.action_date, item.id)
    end

    adj2_chngd = Item.find(2)
    adj4_chngd = Item.find(4)
    adj6_chngd = Item.find(adj6.id)

    assert_equal adj2.amount, adj2_chngd.amount
    assert_equal adj2.adjustment_amount, adj2_chngd.adjustment_amount

    assert_equal adj4.amount, adj4_chngd.amount
    assert_equal adj4.adjustment_amount, adj4_chngd.adjustment_amount

    assert_equal adj6.amount + 200, adj6_chngd.amount
    assert_equal adj6.adjustment_amount, adj6_chngd.adjustment_amount


    plbank1_chngd = MonthlyProfitLoss.find(plbank1.id)
    plbank1_03_chngd = MonthlyProfitLoss.find(plbank1_03.id)
    assert_equal plbank1.amount, plbank1_chngd.amount
    assert_equal plbank1_03.amount + 200, plbank1_03_chngd.amount
  end

  def setup_for_test_parial_items
    from_date = Date.new(2008,9,1)
    to_date = Date.new(2008,9,30)

    # データの準備
    50.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
      #item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.tag_list = 'abc def'
      item.confirmation_required = true
      item.amount = 100 + i
      item.save
    end

    # データの準備
    50.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank21).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.tag_list = 'ghi jkl'
      item.amount = 100 + i
      item.save
    end

    # データの準備(参照されないデータ)
    80.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,10,1) # 参照されない日付
      item.tag_list = 'mno pqr'
      item.amount = 100 + i
      item.save
    end

    # データの準備(参照されないデータ)(別ユーザ)
    80.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = 101 # 参照されないユーザ
      item.user = users(:user101)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.amount = 100 + i
      item.save
    end
  end
  
  def test_partial_items
    setup_for_test_parial_items

    from_date = Date.new(2008,9,1)
    to_date = Date.new(2008,9,30)

    ret_items = Item.find_partial(users(:user1),from_date, to_date)
    assert_equal ITEM_LIST_COUNT, ret_items.size

    
    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:remain=>true})
    assert_equal 100 - ITEM_LIST_COUNT, ret_items.size

    ret_items = Item.find_partial(users(:user1),nil, nil, {:tag => 'abc' })
    assert_equal ITEM_LIST_COUNT, ret_items.size

    ret_items = Item.find_partial(users(:user1),nil, nil, {:remain=>true, :tag => 'abc'})
    assert_equal 50 - ITEM_LIST_COUNT, ret_items.size


    
    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:filter_account_id=>accounts(:bank11).id})
    assert_equal ITEM_LIST_COUNT, ret_items.size

    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:filter_account_id=>accounts(:bank11).id, :remain=>true})
    assert_equal 50 - ITEM_LIST_COUNT, ret_items.size

  end

  def test_partial_items_for_confirmation_required
    setup_for_test_parial_items

    from_date = Date.new(2008,9,1)
    to_date = Date.new(2008,9,30)
    
    cnfmt_rqrd_count = Item.count(:conditions => { :confirmation_required => true})
    ret_items = Item.find_partial(users(:user1),nil, nil, {:mark => 'confirmation_required' })
    assert_equal ITEM_LIST_COUNT, ret_items.size

    ret_items = Item.find_partial(users(:user1),nil, nil, {:remain=>true, :mark => 'confirmation_required'})
    assert_equal cnfmt_rqrd_count - ITEM_LIST_COUNT, ret_items.size
  end

  def test_partial_items_small
    from_date = Date.new(2008,9,1)
    to_date = Date.new(2008,9,30)

    # データの準備
    15.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.amount = 100 + i
      item.save
    end

    # データの準備
    3.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank21).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.amount = 100 + i
      item.save
    end

    # データの準備(参照されないデータ)
    80.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = users(:user1).id
      item.user = users(:user1)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,10,1) # 参照されない日付
      item.amount = 100 + i
      item.save
    end

    # データの準備(参照されないデータ)(別ユーザ)
    80.times do |i|
      item = Item.new
      item.name = 'regular item ' + i.to_s
#      item.user_id = 101 # 参照されないユーザ
      item.user = users(:user101)
      item.from_account_id = accounts(:bank11).id
      item.to_account_id = accounts(:outgo13).id
      item.action_date = Date.new(2008,9,15)
      item.amount = 100 + i
      item.save
    end

    ret_items = Item.find_partial(users(:user1),from_date, to_date)
    assert_equal 18, ret_items.size

    ret_items = Item.find_partial(users(:user1),from_date, to_date, {'remain'=>true})
    assert_equal 0, ret_items.size

    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:remain=>true})
    assert_equal 0, ret_items.size

    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:filter_account_id=>accounts(:bank11).id})
    assert_equal 15, ret_items.size

    ret_items = Item.find_partial(users(:user1),from_date, to_date, {:filter_account_id=>accounts(:bank11).id, :remain=>true})
    assert_equal 0, ret_items.size



#     ret_items = Item.partial_items(users(:user1).id, from_date, to_date)
#     assert_equal 18, ret_items.size

#     ret_items = Item.partial_items(users(:user1).id, from_date, to_date, {'remain'=>true})
#     assert_equal 0, ret_items.size
#     ret_items = Item.partial_items(users(:user1).id, from_date, to_date, {:remain=>true})
#     assert_equal 0, ret_items.size

#     ret_items = Item.partial_items(users(:user1).id, from_date, to_date, {:filter_account_id=>accounts(:bank11).id})
#     assert_equal 15, ret_items.size

#     ret_items = Item.partial_items(users(:user1).id, from_date, to_date, {:filter_account_id=>accounts(:bank11).id, :remain=>true})
#     assert_equal 0, ret_items.size


  end

  def test_collect_account_history
    amount, items = Item.collect_account_history(users(:user1), accounts(:bank1).id, Date.new(2008,2,1), Date.new(2008,2,29))
    assert_equal 8000, amount
    items.each do |item|
      assert item.from_account_id == accounts(:bank1).id || item.to_account_id == accounts(:bank1).id
      assert item.action_date >= Date.new(2008,2,1) &&  item.action_date <= Date.new(2008,2,29)
    end
  end

  def test_user
    item = Item.find(items(:item1).id)
    assert_not_nil item.user
    assert_equal item.user_id, item.user.id
  end

  def test_child_item
    # dummy data
    p_it = Item.new
#    p_it.user_id = 1
    p_it.user = users(:user1)
    p_it.name = 'p hogehoge'
    p_it.from_account_id = 1
    p_it.to_account_id = 2
    p_it.amount = 500
    p_it.action_date = Date.new(2008,2,10)

    c_it = Item.new
#    c_it.user_id = 1
    c_it.user = users(:user1)
    c_it.name = 'c hogehoge'
    c_it.from_account_id = 3
    c_it.to_account_id = 1
    c_it.amount = 500
    c_it.parent_id = p_it.id
    c_it.action_date = Date.new(2008,3,10)

    p_it.child_item = c_it

    p_it.save!
    c_it.parent_item = p_it
    c_it.save!


    new_p = Item.find(p_it.id)
    new_c = Item.find(c_it.id)

    assert_not_nil new_p.child_item
    assert_not_nil new_c.parent_item

  end

  test "parent_idのないitemでupdate_confirmation_requiredを呼びだすと、自身のconfirmation_requiredを更新すること" do
    item = items(:item1)
    assert item.confirmation_required?
    item.update_confirmation_required_of_self_or_parent(false)
    assert !Item.find(item.id).confirmation_required?
  end

  test "parent_idが存在するitemでupdate_confirmation_requiredを呼びだすと、parent_idで指定されたオブジェクトのconfirmation_requiredを更新すること" do
    child_item = items(:credit_refill31)
    assert !child_item.confirmation_required?
    assert !child_item.parent_item.confirmation_required?
    
    child_item.update_confirmation_required_of_self_or_parent(true)
    assert !Item.find(child_item.id).confirmation_required?
    assert Item.find(child_item.parent_id).confirmation_required?
  end
end
