json.entries do
  json.array!(@items) do |item|
    json.id item.id
    json.item_name item.name
    json.from item.from_account_id
    json.to item.to_account_id
    json.action_date item.action_date
    json.amount item.amount
    json.confirmation_required item.confirmation_required
    json.adjustment_amount item.adjustment_amount
    json.tag_list item.tag_list
    if item.child_item
      json.child do
        json.id item.child_item.id
        json.item_name item.child_item.name
        json.from item.child_item.from_account_id
        json.to item.child_item.to_account_id
        json.action_date item.child_item.action_date
        json.amount item.child_item.amount
	json.confirmation_required item.confirmation_required
        json.adjustment_amount item.child_item.adjustment_amount
        json.tag_list item.tag_list
      end
    end
    if item.parent_item
      json.parent do
        json.id item.parent_item.id
        json.item_name item.parent_item.name
        json.from item.parent_item.from_account_id
        json.to item.parent_item.to_account_id
        json.action_date item.parent_item.action_date
        json.amount item.parent_item.amount
	json.confirmation_required item.confirmation_required
        json.adjustment_amount item.parent_item.adjustment_amount
        json.tag_list item.tag_list
      end
    end
  end
end
