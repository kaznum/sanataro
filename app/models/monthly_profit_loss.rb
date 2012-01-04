# -*- coding: utf-8 -*-
class MonthlyProfitLoss < ActiveRecord::Base
  belongs_to :user

  scope :months_before, lambda { |date| where("month < ?", date) }
  
  # 
  # monthly_profit_lossesテーブルを更新する。
  # 削除する場合は、amountを負にする。
  #
  def self.reflect_relatively(user, date, from_id, to_id, amount)
    month = date.beginning_of_month

    f_pl = user.monthly_profit_losses.find_or_initialize_by_month_and_account_id(month, from_id)
    f_pl.amount ||= 0
    f_pl.amount -= amount
    f_pl.save!
    
    t_pl = user.monthly_profit_losses.find_or_initialize_by_month_and_account_id(month, to_id)
    t_pl.amount ||= 0
    t_pl.amount += amount
    t_pl.save!
  end
end
