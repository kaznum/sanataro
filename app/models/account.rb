# -*- coding: utf-8 -*-
class Account < ActiveRecord::Base
  belongs_to :user
  has_many :accounts
  
	validates_presence_of :name
	validates_length_of :name, :in =>1..255
	validates_presence_of :order_no
	validates_format_of :order_no, :with => /^\d+$/
	validates_format_of :account_type, :with => /^account$|^income$|^outgo$/
	validates_format_of :bgcolor, :with => /^[0-9a-f]{6}/i, :allow_nil => true

  scope :active, where(:is_active => true)

	#
	# 残高を取得する
	# my_id でitemのIDを指定すると、そのItemが除外される。また、new_dateと、my_idに該当するitemのaction_dateが同一の場合、
	# new_dateと同じ日のitemデータのうち、my_idよりidがおおきいものは残高計算から除外する
	#
	def self.asset(user, account_id, new_date, my_id=nil) 

		date = new_date
		# amountの算出
		# 前月までのassetを算出
		asset = user.monthly_profit_losses.where(:account_id => account_id).months_before(new_date.beginning_of_month).sum("amount")

    my_item = my_id ? user.items.find_by_id(my_id) : nil

		# 今月のassetの変化を算出
		# 残高情報の新規登録の場合
    outgo_items = income_items = user.items
    
		if my_item.nil?
      outgo_items = outgo_items.action_date_between(date.beginning_of_month, date).where(:from_account_id => account_id)
      income_items = income_items.action_date_between(date.beginning_of_month, date).where(:to_account_id => account_id)
		else
			if  my_item.action_date == date
        outgo_items = outgo_items.where("(action_date >= ? and action_date < ?) or (action_date = ? and id < ?)", date.beginning_of_month, date, date, my_id).where(:from_account_id => account_id)
        income_items = income_items.where("(action_date >= ? and action_date < ?) or (action_date = ? and id < ?)", date.beginning_of_month, date, date, my_id).where(:to_account_id => account_id)
			else # 日付が変更になった場合
        outgo_items = outgo_items.action_date_between(date.beginning_of_month, date).where("id <> ?", my_id).where(:from_account_id => account_id)
        income_items = income_items.action_date_between(date.beginning_of_month, date).where("id <> ?", my_id).where(:to_account_id => account_id)
			end
		end

    outgo = outgo_items.sum("amount")
		income = income_items.sum("amount")
    outgo ||= 0
    income ||= 0
    
		asset += income - outgo

		#
		# 今月以前はplから抽出してしまうため、SQLではmy_item.amountを除外できない
		#
		if my_item && my_item.action_date < date.beginning_of_month
			if my_item.from_account_id == account_id
				asset += my_item.amount
			else
				asset -= my_item.amount
			end
		end

		return asset
	end
end
