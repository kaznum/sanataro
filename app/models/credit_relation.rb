# -*- coding: utf-8 -*-
class CreditRelation < ActiveRecord::Base
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
