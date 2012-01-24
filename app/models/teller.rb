# coding: utf-8
class Teller
  def self.create_entry(args)
    user = args[:user]
    # taggableの問題で、user_idを明示的にしてしないと、tagにuser_idが設定されない
    item = Item.new(args){ |i|
      i.user_id = user.id
    }
    
    ActiveRecord::Base.transaction do 
      item.save!
    end
    affected_items = []
    affected_items << item.child_item if item.child_item

    from_adj = Item.future_adjustment(user, item.action_date, item.from_account_id, item.id)
    to_adj = Item.future_adjustment(user, item.action_date, item.to_account_id, item.id)
    affected_items << from_adj if from_adj
    affected_items << to_adj if to_adj
    
     return [item, affected_items, false]
  rescue ActiveRecord::RecordInvalid
    return [item, affected_items, true]
  end

  def self.destroy_entry(user, id)
    item = user.items.find(id)

    from_adj_item = to_adj_item = child_item = from_adj_credit = to_adj_credit = nil

    ActiveRecord::Base.transaction do 
      item.destroy
      from_adj_item = Item.future_adjustment(user, item.action_date, item.from_account_id, item.id)
      to_adj_item = Item.future_adjustment(user, item.action_date, item.to_account_id, item.id)
      # クレジットカード関連itemの削除
      child_item, from_adj_credit, to_adj_credit = destroy_entry(user, item.child_item)[:itself] if item.child_item
    end
    return {:itself => [item, from_adj_item, to_adj_item], :child => [child_item, from_adj_credit, to_adj_credit]}
  end
end
