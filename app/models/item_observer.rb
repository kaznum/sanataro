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

  def after_update(item)
    user = item.user
    old_from_id = item.changed_attributes["from_account_id"] || item.from_account_id
    old_to_id = item.changed_attributes["to_account_id"] || item.to_account_id
    old_action_date = item.changed_attributes["action_date"] || item.action_date

    if %w(from_account_id to_account_id action_date amount).any?{ |key| item.changed_attributes[key] }
      MonthlyProfitLoss.correct(user, old_from_id, old_action_date.beginning_of_month)
      MonthlyProfitLoss.correct(user, old_to_id, old_action_date.beginning_of_month)
      MonthlyProfitLoss.correct(user, item.from_account_id, item.action_date.beginning_of_month)
      MonthlyProfitLoss.correct(user, item.to_account_id, item.action_date.beginning_of_month)
      Item.update_future_balance(user, old_action_date, old_from_id, item.id)
      Item.update_future_balance(user, old_action_date, old_to_id, item.id)
      Item.update_future_balance(user, item.action_date, item.from_account_id, item.id)
      Item.update_future_balance(user, item.action_date, item.to_account_id, item.id)
    end

    if %w(name from_account_id action_date amount).any?{ |key| item.changed_attributes[key] }
      # クレジットカードの処理
      item.child_item.destroy if item.child_item
      cr = user.credit_relations.find_by_credit_account_id(item.from_account_id)
      if cr
        due_date = credit_payment_date(user, item.from_account_id, item.action_date)
        item.create_child_item!(name: item.name, from_account_id: cr.payment_account_id,
                                to_account_id: item.from_account_id, amount: item.amount,
                                action_date: due_date, user: user)
      end
    end
  end
  
  private
  def credit_payment_date(user, account_id, date)
    user.accounts.where(id: account_id).first.credit_due_date(date)
  end
end
