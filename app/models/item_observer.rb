# -*- coding: utf-8 -*-
class ItemObserver < ActiveRecord::Observer
  def after_create(item)
    user = item.user
    affected_items = []
    MonthlyProfitLoss.correct(user, item.from_account_id, item.action_date.beginning_of_month)
    MonthlyProfitLoss.correct(user, item.to_account_id, item.action_date.beginning_of_month)
    
    Item.update_future_balance(user, item.action_date, item.from_account_id, item.id)
    Item.update_future_balance(user, item.action_date, item.to_account_id, item.id)
    # クレジットカードの処理
    cr = user.credit_relations.find_by_credit_account_id(item.from_account_id)
    unless cr.nil?
      payment_date = credit_payment_date(user, item.from_account_id, item.action_date)
      user.items.create!(name: item.name, from_account_id: cr.payment_account_id,
                         to_account_id: item.from_account_id, amount: item.amount,
                         action_date: payment_date, parent_item: item)
    end
  end


  def after_destroy(item)
    MonthlyProfitLoss.correct(item.user, item.from_account_id, item.action_date.beginning_of_month)
    MonthlyProfitLoss.correct(item.user, item.to_account_id, item.action_date.beginning_of_month)
    Item.update_future_balance(item.user, item.action_date, item.from_account_id, item.id)
    Item.update_future_balance(item.user, item.action_date, item.to_account_id, item.id)
  end

  private
  def credit_payment_date(user, account_id, date)
    user.accounts.where(id: account_id).first.credit_due_date(date)
  end
end
