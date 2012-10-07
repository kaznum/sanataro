class AdjustmentObserver < ActiveRecord::Observer
  def before_create(item)
    user = item.user
    prev_adj = user.adjustments.find_by_to_account_id_and_action_date(item.to_account_id, item.action_date)
    prev_adj.destroy if prev_adj

    item.fill_amount
  end
end

