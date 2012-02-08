# -*- coding: utf-8 -*-
class MonthlyProfitLoss < ActiveRecord::Base
  belongs_to :user

  class << self
    def correct(user, account_id, month)
      pl = user.monthly_profit_losses.find_or_initialize_by_account_id_and_month(account_id, month)
      items_of_month = user.items.where(action_date: month..month.end_of_month)
      pl.amount = items_of_month.where(to_account_id: account_id).sum(:amount) -
        items_of_month.where(from_account_id: account_id).sum(:amount)
      pl.save!
      pl
    end
  end
end
