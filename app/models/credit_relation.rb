# frozen_string_literal: true

class CreditRelation < ActiveRecord::Base
  belongs_to :user

  SETTLEMENT_DAYS = PAYMENT_DAYS = [['1', 1], ['2', 2], ['3', 3], ['4', 4], ['5', 5],
                                    ['6', 6], ['7', 7], ['8', 8], ['9', 9], ['10', 10],
                                    ['11', 11], ['12', 12], ['13', 13], ['14', 14], ['15', 15],
                                    ['16', 16], ['17', 17], ['18', 18], ['19', 19], ['20', 20],
                                    ['21', 21], ['22', 22], ['23', 23], ['24', 24], ['25', 25],
                                    ['26', 26], ['27', 27], ['28', 28], [I18n.t('label.final_day'), 99]]
  PAYMENT_MONTHS =  [[I18n.t('label.same_month'), 0],
                     [I18n.t('label.next_month'), 1],
                     [I18n.t('label.month_after_next'), 2],
                     [I18n.t('label.two_month_after_next'), 3]]

  validate :validate_on_save
  validates :credit_account_id, uniqueness: true, numericality: true
  validates :payment_account_id, numericality: true
  validates :payment_month, inclusion: { in: 0..3 }
  validate :should_not_used_as_payment_account
  validate :should_not_used_as_credit_account

  def validate_on_save
    if settlement_day < 1 || (settlement_day > 28 && settlement_day != 99)
      errors.add(:settlement_day, I18n.t('errors.messages.invalid'))
    end
    if payment_day < 1 || (payment_day > 28 && payment_day != 99)
      errors.add(:payment_day, I18n.t('errors.messages.invalid'))
    end
    if payment_month == 0 && payment_day < settlement_day
      errors.add("settlement_day", I18n.t('errors.messages.before_due'))
    end
    if payment_account_id == credit_account_id
      errors.add("credit_account_id", I18n.t("errors.messages.different_from"))
    end
  end

  def should_not_used_as_payment_account
    crs_in_payments = user.credit_relations.where(payment_account_id: credit_account_id)
    crs_in_payments = crs_in_payments.where.not(id: id)  unless new_record?
    if crs_in_payments.any?
      errors.add("credit_account_id", I18n.t("errors.messages.used_as_payment_account"))
    end
  end

  def should_not_used_as_credit_account
    crs_in_credits = user.credit_relations.where(credit_account_id: payment_account_id)
    crs_in_credits = crs_in_credits.where.not(id: id)  unless new_record?
    if crs_in_credits.any?
      errors.add("payment_account_id", I18n.t("errors.messages.used_as_credit_account"))
    end
  end
end
