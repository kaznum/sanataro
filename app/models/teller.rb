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
    return [item, affected_items.reject(&:nil?).map(&:id).uniq, false]
  end

  def self.update_entry(user, id, args)
    item = user.items.find(id)
    old_action_date = item.action_date
    old_from_id = item.from_account_id
    old_to_id = item.to_account_id
    
    old_child_item = item.child_item
    if old_child_item
      old_from_adj_credit = Item.future_adjustment(user, old_child_item.action_date,
                                                   old_child_item.from_account_id, old_child_item.id)
      old_to_adj_credit = Item.future_adjustment(user, old_child_item.action_date,
                                                 old_child_item.to_account_id, old_child_item.id)
    end
    
    Item.transaction do
      if item.adjustment?
        # 残高調整のため、一度、amountを0にする。
        # (amountを算出するために、他のadjustmentのamountを正しい値にする必要があるため)
        item.update_attributes!(amount: 0)
        item.reload
        
        item.update_attributes!(to_account_id: args[:to_account_id],
                                confirmation_required: args[:confirmation_required],
                                tag_list: args[:tag_list],
                                action_date: args[:action_date],
                                adjustment_amount: args[:adjustment_amount])
      else
        item.update_attributes!(name: args[:name],
                                from_account_id: args[:from_account_id],
                                to_account_id: args[:to_account_id],
                                confirmation_required: args[:confirmation_required],
                                tag_list: args[:tag_list],
                                action_date: args[:action_date],
                                amount: args[:amount])
      end
    end
    item.reload
    
    new_child_item = item.child_item
    if new_child_item
      new_from_adj_credit = Item.future_adjustment(user, new_child_item.action_date,
                                                   new_child_item.from_account_id, new_child_item.id)
      new_to_adj_credit = Item.future_adjustment(user, new_child_item.action_date,
                                                 new_child_item.to_account_id, new_child_item.id)
    end
    
    old_to_item_adj = Item.future_adjustment(user, old_action_date, old_to_id, item.id)
    old_from_item_adj = Item.future_adjustment(user, old_action_date, old_from_id, item.id)
    new_from_item_adj = Item.future_adjustment(user, item.action_date, item.from_account_id, item.id)
    new_to_item_adj = Item.future_adjustment(user, item.action_date, item.to_account_id, item.id)
    
    updated_items = [item]
    updated_items << old_from_item_adj << old_to_item_adj << old_from_adj_credit << old_to_adj_credit
    updated_items << new_from_item_adj << new_to_item_adj
    updated_items << new_child_item << new_from_adj_credit << new_to_adj_credit
    
    deleted_items = [old_child_item]
    
    [item, updated_items.reject(&:nil?).map(&:id).uniq, deleted_items.reject(&:nil?).map(&:id).uniq]
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
