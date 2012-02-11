# -*- coding: utf-8 -*-
class CreditRelation < ActiveRecord::Base
  SETTLEMENT_DAYS = PAYMENT_DAYS = [['1', 1], ['2', 2], ['3', 3], ['4', 4], ['5', 5], ['6', 6], ['7', 7], ['8', 8], ['9', 9], ['10', 10], ['11', 11], ['12', 12], ['13', 13], ['14', 14], ['15', 15], ['16', 16], ['17', 17], ['18', 18], ['19', 19], ['20', 20], ['21', 21], ['22', 22], ['23', 23], ['24', 24], ['25', 25], ['26', 26], ['27', 27], ['28', 28], ['末日', 99]]
  PAYMENT_MONTHS =  [['同月', 0], ['翌月', 1], ['翌々月', 2], ['翌々々月', 3]]

  validate :validate_everytime
  validates_uniqueness_of   :credit_account_id
  validates_numericality_of :credit_account_id
  validates_numericality_of :payment_account_id
  validates_inclusion_of :payment_month, :in=>0..3

  def validate_everytime
    if settlement_day < 1 || (settlement_day > 28 && settlement_day != 99)
      errors.add(:settlement_day, "が不正な値です。")
    end
    if payment_day < 1 || (payment_day > 28 && payment_day != 99)
      errors.add(:payment_day, "が不正な値です。")
    end
    # 引き落としが同月で締め日が引き落とし日より大きい場合はエラー
    if payment_month == 0 && payment_day < settlement_day
      errors.add("settlement_day", "引き落とし日は締め日後でなければなりません。")
    end
    # クレジットカードと引き落としが同じ場合はエラー
    if payment_account_id == credit_account_id
      errors.add("credit_account_id","クレジットカードと引き落とし口座は別でなければなりません。")
    end
  end
end
