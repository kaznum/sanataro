# coding: utf-8
class Teller
  def self.create_entry(args)
    item = Item.new(args)
    ActiveRecord::Base.transaction do 
      item.save!
    end
    user = item.user
    
    affected_items = []
    affected_items << item.child_item

    from_adj = Item.future_adjustment(user, item.action_date, item.from_account_id, item.id)
    to_adj = Item.future_adjustment(user, item.action_date, item.to_account_id, item.id)
    affected_items << from_adj << to_adj
    return [item, affected_items.reject(&:nil?).uniq, false]
  end

  def self.destroy_entry(user, id)
    item = user.items.find(id)

    from_adj_item = to_adj_item = child_item = from_adj_credit = to_adj_credit = nil

    ActiveRecord::Base.transaction do
      item.destroy
    end
    from_adj_item = Item.future_adjustment(user, item.action_date, item.from_account_id, item.id)
    to_adj_item = Item.future_adjustment(user, item.action_date, item.to_account_id, item.id)
    credit_item = item.child_item
    if credit_item
      from_adj_credit = Item.future_adjustment(user, credit_item.action_date, credit_item.from_account_id, credit_item.id)
      to_adj_credit = Item.future_adjustment(user, credit_item.action_date, credit_item.to_account_id, credit_item.id)
    end

    {:itself => [item, from_adj_item, to_adj_item], :child => [credit_item, from_adj_credit, to_adj_credit]}
  end
end
