# frozen_string_literal: true

class ItemObserver < ActiveRecord::Observer
  def after_create(item)
    adjust_pl_of(item)
    adjust_future_balance_of(item)
    item.create_credit_payment!
  end

  def after_destroy(item)
    adjust_pl_of(item)
    adjust_future_balance_of(item)
  end

  def after_update(item)
    update_pl_after_update(item)
    update_future_balance_after_update(item)
    reset_child_item_after_update(item)
  end

  private

  def adjust_pl_of(item)
    MonthlyProfitLoss.correct(item.user, item.from_account_id, item.action_date.beginning_of_month)
    MonthlyProfitLoss.correct(item.user, item.to_account_id, item.action_date.beginning_of_month)
  end

  def adjust_future_balance_of(item)
    Item.update_future_balance(item.user, item.action_date, item.from_account_id, item.id)
    Item.update_future_balance(item.user, item.action_date, item.to_account_id, item.id)
  end

  def update_pl_after_update(item)
    return unless %w(from_account_id to_account_id action_date amount).any? { |key| item.changed_attributes[key] }

    adjust_pl_of_previous_relatives(item)
    adjust_pl_of(item)
  end

  def adjust_pl_of_previous_relatives(item)
    old_from_id = item.changed_attributes['from_account_id'] || item.from_account_id
    old_to_id = item.changed_attributes['to_account_id'] || item.to_account_id
    old_action_date = item.changed_attributes['action_date'] || item.action_date
    MonthlyProfitLoss.correct(item.user, old_from_id, old_action_date.beginning_of_month)
    MonthlyProfitLoss.correct(item.user, old_to_id, old_action_date.beginning_of_month)
  end

  def update_future_balance_after_update(item)
    return unless %w(from_account_id to_account_id action_date amount).any? { |key| item.changed_attributes[key] }

    adjust_future_balance_of_previous_relatives(item)
    adjust_future_balance_of(item)
  end

  def adjust_future_balance_of_previous_relatives(item)
    old_from_id = item.changed_attributes['from_account_id'] || item.from_account_id
    old_to_id = item.changed_attributes['to_account_id'] || item.to_account_id
    old_action_date = item.changed_attributes['action_date'] || item.action_date
    Item.update_future_balance(item.user, old_action_date, old_from_id, item.id)
    Item.update_future_balance(item.user, old_action_date, old_to_id, item.id)
  end

  def reset_child_item_after_update(item)
    if %w(from_account_id action_date).any? { |key| item.changed_attributes[key] }
      item.child_item&.destroy
      item.create_credit_payment!
    elsif %w(name amount).any? { |key| item.changed_attributes[key] } && item.child_item
      item.child_item.update_attributes!(name: item.name, amount: item.amount)
    end
  end
end
