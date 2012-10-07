# coding: utf-8
class Teller
  class << self
    def create_entry(user, args = {})
      args = args.dup
      type = args[:adjustment].to_s.to_bool ? :adjustment : :general_item
      item = user.send(type.to_s.pluralize).build
      item.filter_and_assign_attributes(args)
      ActiveRecord::Base.transaction do
        item.save!
      end

      affected_items = []
      affected_items << item.child_item
      affected_items += future_adjustments_of_item(item)
      affected_items += future_adjustments_of_item(item.child_item)

      [item, affected_items.reject(&:nil?).map(&:id).uniq, false]
    end

    def update_entry(user, id, args)
      item = user.items.find(id)

      updated_items = []
      deleted_items = []
      deleted_items << item.child_item
      updated_items += future_adjustments_of_item(item)
      updated_items += future_adjustments_of_item(item.child_item)

      Item.transaction do
        item = item.update_with_filter!(args)
      end

      updated_items << item
      updated_items << item.child_item
      updated_items += future_adjustments_of_item(item)
      updated_items += future_adjustments_of_item(item.child_item)

      [item, updated_items.reject(&:nil?).map(&:id).uniq, deleted_items.reject(&:nil?).map(&:id).uniq]
    end


    def destroy_entry(user, id)
      item = user.items.find(id)

      deleted_items = []
      updated_items = []
      child_item = item.child_item

      ActiveRecord::Base.transaction do
        item.destroy
      end
      deleted_items << item << child_item
      updated_items += future_adjustments_of_item(item) + future_adjustments_of_item(child_item)

      [updated_items.reject(&:nil?).map(&:id).uniq, deleted_items.reject(&:nil?).map(&:id).uniq]
    end

    private

    def future_adjustments_of_item(item)
      item ? future_adjustments(item.user, item.action_date, [item.from_account_id, item.to_account_id], item.id) : []
    end

    def future_adjustments(user, action_date, account_ids, item_id)
      account_ids.map { |a_id| user.items.future_adjustment(action_date, a_id, item_id) }
    end
  end
end
