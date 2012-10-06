# -*- coding: utf-8 -*-
class Account < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  extend Memoist

  attr_protected :user_id

  belongs_to :user
  has_one :payment_relation, foreign_key: :credit_account_id, class_name: "CreditRelation"
  has_many :credit_relations, foreign_key: :payment_account_id, class_name: "CreditRelation"

  before_validation :trim_bgcolor_if_needed
  before_destroy :error_if_items_exist
  before_destroy :error_if_credit_relations_exist

  after_save :clear_cache

  validates_presence_of :name
  validates_length_of :name, :in =>1..255
  validates_presence_of :order_no
  validates_format_of :order_no, :with => /^\d+$/
  validates_presence_of :type
  validates_format_of :type, :with => /^Banking$|^Income$|^Expense$/
  validates_format_of :bgcolor, :with => /^[0-9a-f]{6}/i, :allow_nil => true

  scope :active, where(:active => true)

  default_scope order("order_no")

  def trim_bgcolor_if_needed
    if bgcolor =~ /^#/
      self.bgcolor = bgcolor.gsub("#","")
    end
  end

  def credit_due_date(action_date)
    cr = payment_relation
    if cr
      earliest_month = cr.payment_month.months.since(action_date)
      due_month = action_date.day <= cr.settlement_day ? earliest_month : 1.month.since(earliest_month)
      due_date = cr.payment_day == 99 ? due_month.end_of_month : Date.new(due_month.year, due_month.month, cr.payment_day)
    end
    due_date
  end

  class << self
    # 特定の日付までの残高を取得する
    # my_id でitemのIDを指定すると、そのItemが除外される。また、
    # dateと、my_idに該当するitemのaction_dateが同一の場合、
    # dateと同じ日のitemデータのうち、my_idよりidがおおきいものは残高計算から除外する
    #
    def asset(user, account_id, date, my_id=nil)
      my_item = my_id ? user.items.find_by_id(my_id) : nil

      # amountの算出
      # 前月までのassetを算出
      asset = self.asset_to_last_month(user, account_id, date, except: my_item)
      # 今月のassetの変化を算出
      if my_item.nil?
        asset += self.asset_beginning_of_month_to_date(user, account_id, date)
      elsif my_item.action_date == date
        asset += self.asset_to_item_of_this_month_except(user, account_id, date, my_id)
      else
        asset += self.asset_to_date_of_this_month_except(user, account_id, date, my_id)
      end

      asset
    end

    def asset_of_month(user, account_ids, month)
      user.monthly_profit_losses.where(account_id: account_ids).where("month <= ?", month.beginning_of_month).sum(:amount)
    end
  end

  private

  def error_if_items_exist
    items_table = Item.arel_table
    item = Item.where(items_table[:from_account_id].eq(id).or(items_table[:to_account_id].eq(id))).first
    if item
      errors[:base] << I18n.t('error.already_used_account') +
        "#{I18n.l(item.action_date)} #{item.name} #{number_to_currency(item.amount)}"
    end
    errors.empty?
  end

  def clear_cache
    Rails.cache.delete_matched(/^user_#{self.user_id}/)
  end

  def error_if_credit_relations_exist
    cr_table = CreditRelation.arel_table
    credit_rel = CreditRelation.where(cr_table[:credit_account_id].eq(id).or(cr_table[:payment_account_id].eq(id))).first
    if credit_rel
      errors[:base] << I18n.t("error.already_has_relation_to_credit")
    end
    errors.empty?
  end

  class << self
    def asset_to_last_month(user, account_id, date, options = {})
      # 今月以前はplから抽出してしまうため、SQLではoption[:except]で指定されたitemの.amountを
      # 除外できない
      asset_of_month(user, account_id, date.beginning_of_month.months_ago(1)) +
        correlate_for_item(account_id, options[:except], date.beginning_of_month)
    end

    def correlate_for_item(account_id, item, this_month)
      if item && item.action_date < this_month
        item.from_account_id == account_id ? item.amount : (-1 * item.amount)
      else
        0
      end
    end

    def asset_to_date_of_this_month_except(user, account_id, date, item_id)
      user.items.action_date_between(date.beginning_of_month, date).where("id <> ?", item_id).scoping do
        expense = Item.where(from_account_id: account_id).sum(:amount)
        income = Item.where(to_account_id: account_id).sum(:amount)
        income - expense
      end
    end

    def asset_to_item_of_this_month_except(user, account_id, date, item_id)
      user.items.where("(action_date >= ? and action_date < ? and id <> ?) or (action_date = ? and id < ?)", date.beginning_of_month, date, item_id,  date, item_id).scoping do
        expense = Item.where(from_account_id: account_id).sum(:amount)
        income = Item.where(to_account_id: account_id).sum(:amount)
        income - expense
      end
    end

    def asset_beginning_of_month_to_date(user, account_id, date)
      user.items.action_date_between(date.beginning_of_month, date).scoping do
        expense = Item.where(from_account_id: account_id).sum(:amount)
        income = Item.where(to_account_id: account_id).sum(:amount)
        income - expense
      end
    end
  end
end
