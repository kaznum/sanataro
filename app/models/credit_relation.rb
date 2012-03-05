# -*- coding: utf-8 -*-
class CreditRelation < ActiveRecord::Base

  attr_protected :user_id
  
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
  validates_uniqueness_of   :credit_account_id
  validates_numericality_of :credit_account_id
  validates_numericality_of :payment_account_id
  validates_inclusion_of :payment_month, in: 0..3

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
end
