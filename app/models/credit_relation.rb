# frozen_string_literal: true

class CreditRelation < ActiveRecord::Base
  belongs_to :user

  SETTLEMENT_DAYS = PAYMENT_DAYS = (1..28).map { |i| [i.to_s, i] } + [[I18n.t('label.final_day'), 99]]
  PAYMENT_MONTHS =  %w(label.same_month
                       label.next_month
                       label.month_after_next
                       label.two_month_after_next).map.with_index { |key, index| [I18n.t(key), index] }

  validate :validate_on_save
  validates :credit_account_id, uniqueness: true, numericality: true
  validates :payment_account_id, numericality: true
  validates :payment_month, inclusion: { in: 0..3 }
  validate :should_not_used_as_payment_account
  validate :should_not_used_as_credit_account

  def validate_on_save
    errors.add(:settlement_day, I18n.t('errors.messages.invalid')) if settlement_day < 1 || (settlement_day > 28 && settlement_day != 99)
    errors.add(:payment_day, I18n.t('errors.messages.invalid')) if payment_day < 1 || (payment_day > 28 && payment_day != 99)
    errors.add(:settlement_day, I18n.t('errors.messages.before_due')) if payment_month.zero? && payment_day < settlement_day
    errors.add(:credit_account_id, I18n.t('errors.messages.different_from')) if payment_account_id == credit_account_id
  end

  def should_not_used_as_payment_account
    crs_in_payments = user.credit_relations.where(payment_account_id: credit_account_id)
    crs_in_payments = crs_in_payments.where.not(id: id) unless new_record?
    errors.add(:credit_account_id, I18n.t('errors.messages.used_as_payment_account')) if crs_in_payments.any?
  end

  def should_not_used_as_credit_account
    crs_in_credits = user.credit_relations.where(credit_account_id: payment_account_id)
    crs_in_credits = crs_in_credits.where.not(id: id) unless new_record?
    errors.add(:payment_account_id, I18n.t('errors.messages.used_as_credit_account')) if crs_in_credits.any?
  end
end
