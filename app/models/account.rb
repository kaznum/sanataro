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

  validates_presence_of :name
  validates_length_of :name, :in =>1..255
  validates_presence_of :order_no
  validates_format_of :order_no, :with => /^\d+$/
  validates_format_of :account_type, :with => /^account$|^income$|^outgo$/
  validates_format_of :bgcolor, :with => /^[0-9a-f]{6}/i, :allow_nil => true

  scope :active, where(:active => true)
  scope :account, where(account_type: 'account')
  scope :income, where(account_type: 'income')
  scope :outgo, where(account_type: 'outgo')

  default_scope order("order_no")

  def trim_bgcolor_if_needed
    if bgcolor =~ /^#/
      self.bgcolor = bgcolor.gsub("#","")
    end
  end

  def credit_due_date(action_date)
    cr = payment_relation
    unless cr.nil?
      earliest_month = action_date.beginning_of_month.months_since(cr.payment_month)
      due_month = action_date.day <= cr.settlement_day ? earliest_month : earliest_month.months_since(1)
      due_date = cr.payment_day == 99 ? due_month.end_of_month : Date.new(due_month.year, due_month.month, cr.payment_day)
    end
    return due_date
  end

  class << self
    %w(income outgo account).each do |name|
      define_method("#{name}_ids".to_sym) do
        send(name.to_sym).map(&:id)
      end
    end

    # def income_ids
    #   self.income.map&(:id)
    # end
    # def outgo_ids
    #   self.outog.map&(:id)
    # end
    # def account_ids
    #   self.account.map&(:id)
    # end

    #
    # 特定の日付までの残高を取得する
    # my_id でitemのIDを指定すると、そのItemが除外される。また、
    # dateと、my_idに該当するitemのaction_dateが同一の場合、
    # dateと同じ日のitemデータのうち、my_idよりidがおおきいものは残高計算から除外する
    #
    def asset(user, account_id, date, my_id=nil)
      my_item = my_id ? user.items.find_by_id(my_id) : nil

      # amountの算出
      # 前月までのassetを算出
      asset = self.asset_to_last_month_except_self(user, account_id, my_item, date)
      # 今月のassetの変化を算出
      if my_item.nil?
        asset += self.asset_beginning_of_month_to_date(user, account_id, date)
      elsif my_item.action_date == date
        asset += self.asset_to_item_of_this_month_except_self(user, account_id, my_id, date)
      else
        asset += self.asset_to_date_of_this_month_except_self(user, account_id, my_id, date)
      end

      return asset
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

  def error_if_credit_relations_exist
    cr_table = CreditRelation.arel_table
    credit_rel = CreditRelation.where(cr_table[:credit_account_id].eq(id).or(cr_table[:payment_account_id].eq(id))).first
    if credit_rel
      errors[:base] << I18n.t("error.already_has_relation_to_credit")
    end
    errors.empty?
  end

  class << self
    def asset_to_last_month_except_self(user, account_id, item, date)
      #
      # 今月以前はplから抽出してしまうため、SQLではmy_item.amountを除外できない
      #
      asset_of_month(user, account_id, date.beginning_of_month.months_ago(1)) +
        correlate_for_self(account_id, item, date.beginning_of_month)
    end

    def correlate_for_self(account_id, item, this_month)
      retval = 0
      if item && item.action_date < this_month
        retval = item.from_account_id == account_id ? item.amount : (-1 * item.amount)
      end
      retval
    end

    def asset_to_date_of_this_month_except_self(user, account_id, item_id, date)
      items_scope = user.items.action_date_between(date.beginning_of_month, date).where("id <> ?", item_id)
      outgo = items_scope.where(from_account_id: account_id).sum(:amount)
      income = items_scope.where(to_account_id: account_id).sum(:amount)
      income - outgo
    end

    def asset_to_item_of_this_month_except_self(user, account_id, item_id, date)
      items_scope = user.items.where("(action_date >= ? and action_date < ? and id <> ?) or (action_date = ? and id < ?)", date.beginning_of_month, date, item_id,  date, item_id)
      outgo = items_scope.where(from_account_id: account_id).sum(:amount)
      income = items_scope.where(to_account_id: account_id).sum(:amount)
      income - outgo
    end

    def asset_beginning_of_month_to_date(user, account_id, date)
      items_scope = user.items.action_date_between(date.beginning_of_month, date)
      outgo = items_scope.where(from_account_id: account_id).sum(:amount)
      income = items_scope.where(to_account_id: account_id).sum(:amount)
      income - outgo
    end
  end
end
