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
    affected_items += self.future_adjustments_of_item(item)
    affected_items += self.future_adjustments_of_item(item.child_item)
    
    [item, affected_items.reject(&:nil?).map(&:id).uniq, false]
  end

  def self.update_entry(user, id, args)
    item = user.items.find(id)
    
    updated_items = []
    deleted_items = []
    deleted_items << item.child_item
    updated_items += self.future_adjustments_of_item(item)
    updated_items += self.future_adjustments_of_item(item.child_item)
    
    Item.transaction do
      item = item.adjustment? ? self.update_adjustment!(item, args) : self.update_regular_entry!(item, args)
    end

    updated_items << item
    updated_items << item.child_item
    updated_items += self.future_adjustments_of_item(item)
    updated_items += self.future_adjustments_of_item(item.child_item)
    
    [item, updated_items.reject(&:nil?).map(&:id).uniq, deleted_items.reject(&:nil?).map(&:id).uniq]
  end

  def self.update_regular_entry!(item, args)
    item.update_attributes!(name: args[:name],
                            from_account_id: args[:from_account_id],
                            to_account_id: args[:to_account_id],
                            confirmation_required: args[:confirmation_required],
                            tag_list: args[:tag_list],
                            action_date: args[:action_date],
                            amount: args[:amount])
    item.reload
    item
  end
  
  def self.update_adjustment!(item, args)
    # For simple adjustment, set amount = 0 at once
    # This is to set correct amounts of other adjustment items to calcurate "amount" later.
    attrs = {to_account_id: args[:to_account_id],
      confirmation_required: args[:confirmation_required],
      tag_list: args[:tag_list],
      action_date: args[:action_date],
      adjustment_amount: args[:adjustment_amount]}
    # The following is only for JRuby + SQLite3
    # Primarily, this code isn't required, but the result of update_attributes!(amount:0)
    # got stored unfortunately when an exception happens after the code, so in advance,
    # check the validation of the parameters.
    # This problem has been seen the following environment.
    # JRuby 1.6.7, head(2012-4-6)
    # activerecord-jdbcsqlite3-adapter (1.2.2)
    # activerecord-jdbc-adapter (1.2.2)
    # jdbc-sqlite3 (3.7.2)
    item.assign_attributes(attrs)
    item.valid? || (raise ActiveRecord::RecordInvalid.new(item))
    item.reload
    # The End of code Only for JRuby + SQLite3
    item.update_attributes!(amount: 0)
    item.reload
    item.update_attributes!(attrs)
    item.reload
    item
  end
  
  def self.destroy_entry(user, id)
    item = user.items.find(id)

    deleted_items = []
    updated_items = []
    child_item = item.child_item

    ActiveRecord::Base.transaction do
      item.destroy
    end
    deleted_items << item << child_item
    updated_items += self.future_adjustments_of_item(item) + self.future_adjustments_of_item(child_item)

    [updated_items.reject(&:nil?).map(&:id).uniq, deleted_items.reject(&:nil?).map(&:id).uniq]
  end

  def self.future_adjustments_of_item(item)
    item ? self.future_adjustments(item.user, item.action_date, [item.from_account_id, item.to_account_id], item.id) : []
  end

  def self.future_adjustments(user, action_date, account_ids, item_id)
    account_ids.map { |a_id| Item.future_adjustment(user, action_date, a_id, item_id) }
  end
end
