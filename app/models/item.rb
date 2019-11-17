# frozen_string_literal: true

class Item < ActiveRecord::Base
  sanataro_taggable

  belongs_to :user
  belongs_to :parent_item, class_name: 'GeneralItem', foreign_key: 'parent_id'
  has_one :child_item, class_name: 'GeneralItem', foreign_key: 'parent_id', dependent: :destroy

  validate :validates_action_date_range

  attr_accessor :p_year, :p_month, :p_day

  validates :user_id, presence: true, format: { with: /\A\d+\z/ }
  validates :name, presence: true, length: { in: 1..255 }
  validates :from_account_id, presence: true, format: { with: /\A-?\d+\z/ }
  validates :to_account_id, presence: true, format: { with: /\A-?\d+\z/ }
  validates :amount, presence: true, format: { with: /\A-?\d+\z/ }
  validates :action_date, presence: true
  validates :type, presence: true

  validate :action_date_should_be_larger_than_that_of_parent_item

  validate :from_account_id_should_be_income_or_banking
  validate :to_account_id_should_be_expense_or_banking
  validate :from_and_to_account_id_should_not_be_same

  before_validation :set_action_date
  before_validation :fill_amount

  scope :of_account_id, ->(account_id) { where(arel_table[:from_account_id].eq(account_id).or(arel_table[:to_account_id].eq(account_id))) }
  scope :action_date_between, ->(from, to) { where(action_date: from..to) }
  scope :confirmation_required, -> { where(confirmation_required: true) }
  scope :default_limit, -> { limit(Settings.item_list_count) }
  # FIX ME
  #
  # limit is fixed number.
  scope :remaining, -> { offset(Settings.item_list_count).limit(999_999) }
  scope :order_of_entries, -> { order(arel_table[:action_date].desc, arel_table[:id].desc) }

  def validates_action_date_range
    today = Date.today
    return unless action_date

    errors.add(:action_date, I18n.t('errors.messages.until_since_today', year: 2, date: I18n.l(Date.new(today.year + 2, today.month, 1) - 1, format: :year_month))) if action_date >= 2.years.since(Date.today)
    since = Date.new(2006, 1, 1)
    errors.add(:action_date, I18n.t('errors.messages.since_until_today', date: I18n.l(since))) if action_date < since
  end

  def adjustment?
    is_a?(Adjustment) || type == 'Adjustment'
  end

  def year
    p_year.presence || action_date.try(:year)
  end

  def month
    p_month.presence || action_date.try(:month)
  end

  def day
    p_day.presence || action_date.try(:day)
  end

  def year=(arg)
    if arg.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_year = arg.to_i
      set_action_date
    end
  end

  def month=(arg)
    if arg.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_month = arg.to_i
      set_action_date
    end
  end

  def day=(arg)
    if arg.blank?
      self.p_year = self.p_month = self.p_day = nil
      self.action_date = nil
    else
      self.p_day = arg.to_i
      set_action_date
    end
  end

  def update_confirmation_required_of_self_or_parent(required)
    if parent_item
      parent_item.update_attributes(confirmation_required: required)
    else
      update_attributes(confirmation_required: required)
    end
  end

  def to_custom_hash
    {
      entry: {
        id: id, name: name, action_date: action_date,
        from_account_id: from_account_id, to_account_id: to_account_id,
        amount: amount, confirmation_required: confirmation_required?,
        tags: tag_list.split(' ').sort,
        child_id: child_item.try(:id), parent_id: parent_id
      }
    }
  end

  def create_credit_payment!
    cr = user.credit_relations.find_by_credit_account_id(from_account_id)
    return unless cr

    due_date = user.accounts.where(id: from_account_id).first.credit_due_date(action_date)
    create_child_item!(name: name, from_account_id: cr.payment_account_id,
                       to_account_id: from_account_id, amount: amount,
                       action_date: due_date, user: user)
  end

  class << self
    def calc_amount(amount)
      return 0 unless amount

      amount_to_calc = amount.to_s.gsub(/\s/, '').gsub(/,/, '')
      unless %r|^[\.\-\*\+/\%\d\(\)]+$| =~ amount_to_calc
        raise SyntaxError
      end

      amount_to_calc.gsub!(%r|/|, '/1.0/')
      eval(amount_to_calc).to_i # rubocop:disable Security/Eval
    end
  end

  protected

  def set_action_date
    if p_year.blank? && p_month.blank? && p_day.blank?
      # DO NOTHING
    elsif p_year.blank? || p_month.blank? || p_day.blank?
      # どれか一つ入力されている場合、日付が間違っている、もしくは入力不足の可能性がある。
      self.action_date = nil
    elsif Date.valid_date?(p_year, p_month, p_day)
      self.action_date = Date.new(p_year, p_month, p_day)
    else
      self.action_date = nil
    end
  end

  class << self
    def update_future_balance(user, action_date, account_id, item_id)
      return if account_id == -1

      item_adj = user.adjustments.future_adjustment(action_date, account_id, item_id)

      if item_adj
        amount_to_adj = Account.asset(user, account_id, item_adj.action_date, item_adj.id)
        amount = item_adj.adjustment_amount - amount_to_adj
        # Do not update without comparing because the following processes is very expensive and ItemObserver
        # could update other items unnecessorily.
        if item_adj.amount != amount
          item_adj.update_attributes!(amount: amount)
          MonthlyProfitLoss.correct(user, account_id, item_adj.action_date.beginning_of_month)
          MonthlyProfitLoss.correct(user, -1, item_adj.action_date.beginning_of_month)
        else
          item_adj = nil
        end
      end

      item_adj
    end

    def future_adjustment(action_date, account_id, item_id)
      where(to_account_id: account_id, type: 'Adjustment')
        .where('(action_date > ? AND id <> ?) OR (action_date = ? AND id > ?)',
               action_date, item_id, action_date, item_id).order('action_date, id').first
    end

    #
    # get items from db
    # options
    #    :remain  true: 非表示の部分を取得
    #    :filter_account_id: 抽出するaccount_id
    #    :tag タグにより検索(この場合、from_date, to_dateは無視される)
    #    :mark mark(confirmation_requiredなど)により検索(この場合、from_date, to_dateは無視される)
    #
    def partials(from_date, to_date, filter_options = {})
      options = symbolize_keys(filter_options)
      items = self
      if options[:tag].present?
        ret_items = options[:remain] ? items.remainings_by_tag(options[:tag]) : items.partials_by_tag(options[:tag])
      elsif options[:keyword].present?
        ret_items = options[:remain] ? items.remainings_by_keyword(options[:keyword]) : items.partials_by_keyword(options[:keyword])
      else
        items = if options[:mark] == 'confirmation_required'
                  items.confirmation_required
                else
                  items.action_date_between(from_date, to_date).includes(:user, :tags, :child_item)
                end
        items = items.of_account_id(options[:filter_account_id]) if options[:filter_account_id].present?
        items = items.order_of_entries
        ret_items = options[:remain] ? items.remaining : items.default_limit
      end

      ret_items
    end

    def symbolize_keys(args = {})
      options = {}
      args.each do |key, value|
        options[key.to_sym] = value
      end
      options
    end

    def partials_by_tag(tag)
      tagged_with(tag).order_of_entries.limit(Settings.item_list_count)
    end

    def remainings_by_tag(tag)
      # FIX ME
      #
      # limit is fixed number.
      tagged_with(tag).order_of_entries.remaining
    end

    def where_keyword_matches(str)
      keywords = str.strip.split(/\s+/).map { |key| "%#{key.gsub(/[%_!]/) { |s| '!' + s }}%" }
      where(arel_table[:name].matches_all(keywords, '!'))
    end

    def partials_by_keyword(keyword)
      where_keyword_matches(keyword).order_of_entries.limit(Settings.item_list_count)
    end

    def remainings_by_keyword(keyword)
      # FIX ME
      #
      # limit is fixed number.
      where_keyword_matches(keyword).order_of_entries.remaining
    end

    def collect_account_history(user, account_id, from_date, to_date)
      items = user.items.action_date_between(from_date, to_date).of_account_id(account_id).order('action_date')
      remain_amount = user.monthly_profit_losses.where('month < ?', from_date).where(account_id: account_id).sum('amount')
      [remain_amount, items]
    end
  end

  private

  def action_date_should_be_larger_than_that_of_parent_item
    p_item = parent_item
    p_item && action_date <= p_item.action_date &&
      errors.add(:action_date, I18n.t('errors.messages.after_credit_item', date: I18n.l(p_item.action_date)))
  end

  def from_account_id_should_be_income_or_banking
    from_account_id != -1 &&
      !user.income_ids.include?(from_account_id) &&
        !user.banking_ids.include?(from_account_id) &&
          errors.add(:from_account_id, I18n.t('errors.messages.invalid'))
  end

  def to_account_id_should_be_expense_or_banking
    !user.expense_ids.include?(to_account_id) &&
      !user.banking_ids.include?(to_account_id) &&
        errors.add(:to_account_id, I18n.t('errors.messages.invalid'))
  end

  def from_and_to_account_id_should_not_be_same
    from_account_id == to_account_id &&
      errors.add(:from_account_id, I18n.t('errors.messages.same_account'))
  end
end
