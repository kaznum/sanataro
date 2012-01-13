# -*- coding: utf-8 -*-
class Item < ActiveRecord::Base
  acts_as_taggable

  belongs_to :parent_item, :class_name => "Item", :foreign_key => 'parent_id'
  has_one :child_item, :class_name => "Item", :foreign_key => 'parent_id'
  belongs_to :user

  validate :validate_everytime

#  before_validation :set_user_id

  attr_accessor :p_year, :p_month, :p_day
  N_("Item|Year")
  N_("Item|Month")
  N_("Item|Day")

  validates_presence_of :user_id
  validates_format_of :user_id, :with => /^\d+$/
  validates_presence_of :name
  validates_length_of :name, :in =>1..255
  validates_presence_of :from_account_id
  validates_format_of :from_account_id, :with => /^-?\d+$/
  validates_presence_of :to_account_id
  validates_format_of :to_account_id, :with => /^\d+$/
  validates_presence_of :amount
  validates_format_of :amount, :with => /^-?\d+$/
  validates_presence_of :action_date

  before_validation :set_action_date
  
  ORDER_OF_ENTRIES_LIST = "action_date desc, id desc"
  scope :only_account, lambda { |account_id|  where("from_account_id = ? or to_account_id = ?", account_id, account_id) }
  scope :action_date_between, lambda { |from, to| where("action_date between ? and ?", from, to)}
  scope :confirmation_required, where(:confirmation_required => true)
  scope :default_limit, limit(ITEM_LIST_COUNT)
  scope :remaining, offset(ITEM_LIST_COUNT)
  scope :order_for_entries_list, order(ORDER_OF_ENTRIES_LIST)
  
  def validate_everytime
    today = Date.today
    unless action_date.nil?
      if self.action_date >= 2.years.since(Date.today)
        errors.add(:action_date, "日付は本日より2年先(" + (Date.new(today.year + 2, today.month, 1) - 1).strftime("%Y年%m月") + ")まで入力可能です。")
      end
      if self.action_date < Date.new(2006, 1, 1)
        errors.add(:action_date, _("Date has to be after the year 2006."))
      end
    end
  end

  def year
    self.p_year.presence || self.action_date.try(:year)
  end

  def month
    self.p_month.presence || self.action_date.try(:month)
  end
  
  def day
    self.p_day.presence || self.action_date.try(:day)
  end

  def year=(y)
    if y.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_year =  y.to_i
      set_action_date
    end
  end
  def month=(m)
    if m.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_month = m.to_i
      set_action_date
    end
  end
  def day=(d)
    if d.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_day = d.to_i
      set_action_date
    end
  end

  def update_confirmation_required_of_self_or_parent(required)
    if self.parent_item
      self.parent_item.update_attributes(:confirmation_required => required)
    else
      self.update_attributes(:confirmation_required => required)
    end
  end

  def to_custom_hash
    { :entry => {
        :id => id, :name => name, :action_date => action_date,
        :from_account_id => from_account_id, :to_account_id => to_account_id,
        :amount => amount, :confirmation_required => confirmation_required?,
        :tags => tag_list.split(' ').sort,
        :child_id => child_id, :parent_id => parent_id } }
  end
  
  protected  

  def set_action_date
    if self.p_year.blank? && self.p_month.blank? && self.p_day.blank?
      # DO NOTHING
    elsif self.p_year.blank? || self.p_month.blank? || self.p_day.blank?
      # どれか一つ入力されている場合、日付が間違っている、もしくは入力不足の可能性がある。
      self.action_date = nil
    elsif Date.valid_date?(self.p_year, self.p_month, self.p_day)
      self.action_date = Date.new(self.p_year, self.p_month, self.p_day)
    else
      self.action_date = nil
    end

  end

  def self.update_future_balance(user, action_date, account_id, item_id)
    return if account_id == -1
    
    item_adj = user.items.where(to_account_id: account_id,
                                is_adjustment: true).where("(action_date > ? AND id <> ?) OR (action_date = ? AND id > ?)",
                                                           action_date, item_id, action_date, item_id).order("action_date, id").first
    if item_adj
      amount_to_adj = Account.asset(user, account_id, item_adj.action_date, item_adj.id)
      item_adj.amount = item_adj.adjustment_amount - amount_to_adj
      item_adj.save!

      MonthlyProfitLoss.correct(user, account_id, item_adj.action_date.beginning_of_month)
      MonthlyProfitLoss.correct(user, -1, item_adj.action_date.beginning_of_month)
    end

    item_adj
  end
  
  #(obsolete self.update_future_balance(user, action_date, account_id, item_id)で置き換え)
  # 残高調整内部処理
  # 直近の未来の残高調整アイテムを1件取得し、amountの分だけ、金額に追加することにより、残高調整による不明金調整を行なう
  #
  def self.adjust_future_balance(user, account_id, amount, action_date, item_id=nil)

    return if account_id == -1

    if item_id.nil?
      item_adj = user.items.order("action_date, id").where(to_account_id: account_id, is_adjustment: true).where("action_date > ?", action_date).first
    else
      item_adj = user.items.where(to_account_id: account_id,
                                  is_adjustment: true).where("(action_date > ? AND id <> ?) OR (action_date = ? AND id > ?)",
                                                             action_date, item_id, action_date, item_id).order("action_date, id").first
    end
    unless item_adj.nil?
      item_adj.amount += amount
      item_adj.save!
      MonthlyProfitLoss.reflect_relatively(user,
                         item_adj.action_date.beginning_of_month,
                         -1,
                         account_id,
                         amount)
    end

    return item_adj
  end

  #
  # get items from db
  # options
  #    :remain  true: 非表示の部分を取得
  #    :filter_account_id: 抽出するaccount_id
  #    :tag タグにより検索(この場合、from_date, to_dateは無視される)
  #    :mark mark(confirmation_requiredなど)により検索(この場合、from_date, to_dateは無視される)
  #
  def self.find_partial(user, from_date, to_date, filter_options={})
    options = symbolize_keys(filter_options)
    
    if options[:tag].present?
      ret_items = options[:remain] ? user.items.remainings_by_tag(options[:tag]) :
        user.items.partials_by_tag(options[:tag])
    else
      items = user.items
      items = (options[:mark] == 'confirmation_required') ? items.confirmation_required :
        items.action_date_between(from_date, to_date).includes(:user, :tags)
      options[:filter_account_id].present? &&
        items = items.only_account(options[:filter_account_id])
      items = items.order_for_entries_list
      ret_items = options[:remain] ? items.remaining.all : items.default_limit.all
    end
    
    return ret_items
  end

  def self.symbolize_keys(args = {})
    options = {}
    args.each do |key, value|
      options[key.to_sym] = value
    end
    options
  end

  def self.partials_by_tag(tag)
    # FIX ME
    #
    # In fact, it should call call the method like  the following
    # self.find_tagged_with(tag).default_limit.order(ORDER_OF_ENTRIES_LIST)
    self.find_tagged_with(tag,
                          :limit => ITEM_LIST_COUNT,
                          :order => ORDER_OF_ENTRIES_LIST)
  end

  def self.remainings_by_tag(tag)
    # FIX ME
    #
    # In fact, it should call the method like the following
    # self.find_tagged_with(tag).remaining.order(ORDER_OF_ENTRIES_LIST)
    self.find_tagged_with(tag,
                          :limit => 999999,
                          :offset => ITEM_LIST_COUNT,
                          :order => ORDER_OF_ENTRIES_LIST)
  end
  
  #
  # History収集の実処理
  #
  def self.collect_account_history(user, account_id, from_date, to_date)
    items = user.items.action_date_between(from_date, to_date).only_account(account_id).order("action_date")
    remain_amount = user.monthly_profit_losses.where("month < ? and account_id = ?", from_date, account_id).sum('amount')
    [remain_amount, items]
  end


end
