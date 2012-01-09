# -*- coding: utf-8 -*-
class Account < ActiveRecord::Base
  belongs_to :user
  has_many :accounts
  
  validates_presence_of :name
  validates_length_of :name, :in =>1..255
  validates_presence_of :order_no
  validates_format_of :order_no, :with => /^\d+$/
  validates_format_of :account_type, :with => /^account$|^income$|^outgo$/
  validates_format_of :bgcolor, :with => /^[0-9a-f]{6}/i, :allow_nil => true

  scope :active, where(:is_active => true)

  #
  # 特定の日付までの残高を取得する
  # my_id でitemのIDを指定すると、そのItemが除外される。また、
  # dateと、my_idに該当するitemのaction_dateが同一の場合、
  # dateと同じ日のitemデータのうち、my_idよりidがおおきいものは残高計算から除外する
  #
  def self.asset(user, account_id, date, my_id=nil) 
    my_item = my_id ? user.items.find_by_id(my_id) : nil

    # amountの算出
    # 前月までのassetを算出
    asset = self.asset_to_last_month_except_self(user, account_id, my_item, date)
    # 今月のassetの変化を算出
    if my_item.nil?
      asset += self.asset_to_item_of_this_month(user, account_id, date)
    elsif my_item.action_date == date
      asset += self.asset_to_item_of_this_month_except_self(user, account_id, my_id, date)
    else
      # 更新により日付が変更になった場合
      asset += self.asset_to_date_of_this_month_except_self(user, account_id, my_id, date)
    end

    return asset
  end

  def self.asset_of_month(user, account_ids, month)
    user.monthly_profit_losses.where(account_id: account_ids).where("month <= ?", month.beginning_of_month).sum(:amount)
  end
  
  private
  def self.asset_to_last_month_except_self(user, account_id, item, date)
    #
    # 今月以前はplから抽出してしまうため、SQLではmy_item.amountを除外できない
    #
    asset_of_month(user, account_id, date.beginning_of_month.months_ago(1)) +
      correlate_for_self(account_id, item, date.beginning_of_month)
  end
  
  def self.correlate_for_self(account_id, item, this_month)
    retval = 0
    if item && item.action_date < this_month
      retval = item.from_account_id == account_id ? item.amount : (-1 * item.amount)
    end
    retval
  end

  def self.asset_to_date_of_this_month_except_self(user, account_id, item_id, date)
    items_scope = user.items.action_date_between(date.beginning_of_month, date).where("id <> ?", item_id)
    outgo = items_scope.where(from_account_id: account_id).sum(:amount)
    income = items_scope.where(to_account_id: account_id).sum(:amount)
    income - outgo
  end

  def self.asset_to_item_of_this_month_except_self(user, account_id, item_id, date)
    items_scope = user.items.where("(action_date >= ? and action_date < ?) or (action_date = ? and id < ?)", date.beginning_of_month, date, date, item_id)
    outgo = items_scope.where(from_account_id: account_id).sum(:amount)
    income = items_scope.where(to_account_id: account_id).sum(:amount)
    income - outgo
  end

  def self.asset_to_item_of_this_month(user, account_id, date)
    items_scope = user.items.action_date_between(date.beginning_of_month, date)
    outgo = items_scope.where(from_account_id: account_id).sum(:amount)
    income = items_scope.where(to_account_id: account_id).sum(:amount)
    income - outgo
  end

end
