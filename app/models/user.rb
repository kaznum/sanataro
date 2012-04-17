# -*- coding: utf-8 -*-
class User < ActiveRecord::Base
  attr_protected :login
  attr_accessor :password_plain, :password_confirmation
  acts_as_tagger
  has_many :items
  has_many :monthly_profit_losses
  has_many :accounts
  has_many :credit_relations
  has_many :autologin_keys

  validate :validates_password_confirmation
  validates_presence_of :login
  validates_presence_of :password_plain, :if => :password_required?
  validates_presence_of :email
  validates_format_of :login, :with => /^[A-Za-z0-9_-]+$/
  validates_length_of :login, :in =>3..10
  validates_format_of :password_plain, :with => /^[A-Za-z0-9_-]+$/, :if => :password_required?
  validates_length_of :password_plain, :in =>6..10, :if => :password_required?
  validates_uniqueness_of :login, :message => I18n.t("errors.messages.exclusion")

  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_length_of :email, :in =>5..255

  before_save :hash_password

  def validates_password_confirmation
    errors.add("password_plain", I18n.t("errors.messages.confirmation")) if self.password_required? && self.password_plain != self.password_confirmation
  end

  def password_required?
    self.password.blank? || !self.password_plain.blank?
  end

  def hash_password
    return if self.password_plain.blank?
    self.password = CommonUtil.crypt(login + self.password_plain)
  end

  def get_categorized_accounts
    accounts = self.accounts.active.order("account_type, order_no")
    from  = Array.new
    to  = Array.new
    bank_accounts = Array.new
    all_accounts  = Hash.new
    all_accounts.default = "(#{I18n.t('label.unknown')})"
    income_ids = Array.new
    outgo_ids = Array.new
    account_ids = Array.new
    account_bgcolors = Hash.new

    tmp_accounts = Array.new

    accounts.each do |a|
      case a.account_type
      when 'outgo'
        to.push [a.name, a.id.to_s]
        outgo_ids.push a.id
      when 'income'
        from.push [a.name, a.id.to_s]
        income_ids.push a.id
      when 'account'
        tmp_accounts.push [a.name, a.id.to_s]
        from.push [a.name, a.id.to_s]
        bank_accounts.push [a.name, a.id.to_s]
        account_ids.push a.id
      end
      all_accounts[a.id] = a.name
      account_bgcolors[a.id] = a.bgcolor unless a.bgcolor.nil?
    end

    to += tmp_accounts

    return { :from_accounts => from,
      :to_accounts => to,
      :bank_accounts => bank_accounts,
      :all_accounts => all_accounts,
      :income_ids => income_ids,
      :outgo_ids => outgo_ids,
      :account_ids => account_ids,
      :account_bgcolors => account_bgcolors
    }
  end

  def deliver_signup_confirmation
    Mailer.signup_confirmation(self).deliver
  end

  def deliver_signup_complete
    Mailer.signup_complete(self).deliver
  end

  def store_sample
    account1 = self.accounts.create(:name => '財布', :order_no => 10, :account_type => 'account')
    account2 = self.accounts.create(:name => '銀行A', :order_no => 20, :account_type => 'account')
    account3 = self.accounts.create(:name => '銀行B', :order_no => 30, :account_type => 'account')
    account4_cr = self.accounts.create(:name => 'クレジットカード', :order_no => 40, :account_type => 'account')

    income1 = self.accounts.create(:name => '給与', :order_no => 10, :account_type => 'income')
    income2 = self.accounts.create(:name => '賞与', :order_no => 20, :account_type => 'income')
    income3 = self.accounts.create(:name => '雑収入', :order_no => 30, :account_type => 'income')

    outgo1 = self.accounts.create(:name => '食費', :order_no => 10, :account_type => 'outgo')
    outgo2 = self.accounts.create(:name => '光熱費', :order_no => 20, :account_type => 'outgo')
    outgo3 = self.accounts.create(:name => '住居費', :order_no => 30, :account_type => 'outgo')
    outgo4 = self.accounts.create(:name => '美容費', :order_no => 40, :account_type => 'outgo')
    outgo5 = self.accounts.create(:name => '衛生費', :order_no => 50, :account_type => 'outgo')
    outgo6 = self.accounts.create(:name => '雑費', :order_no => 60, :account_type => 'outgo')

    credit_relation = self.credit_relations.create(:credit_account_id => account4_cr.id, :payment_account_id => account3.id, :settlement_day => 25, :payment_month => 2, :payment_day => 4)

    item_income = self.items.create(:name => 'サンプル収入(消してかまいません)', :from_account_id => income3.id, :to_account_id => account1.id, :amount => 1000, :action_date => Date.today)
    item_outgo = self.items.create(:name => 'サンプル(消してかまいません)', :from_account_id => account1.id, :to_account_id => outgo1.id, :amount => 250, :action_date => Date.today, :tag_list => 'タグもOK')
  end
end
