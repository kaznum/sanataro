item = @item
json.key_format! :camelize => :lower
json.entry do
  json.id item.id
  json.name item.name
  json.from_account_id item.from_account_id
  json.to_account_id item.to_account_id
  json.action_date item.action_date
  json.amount item.amount
  json.adjustment_amount item.adjustment_amount
  json.tag_list item.tag_list
  if item.child_item
    json.child do
      json.id item.child_item.id
      json.name item.child_item.name
      json.from_account_id item.child_item.from_account_id
      json.to_account_id item.child_item.to_account_id
      json.action_date item.child_item.action_date
      json.amount item.child_item.amount
      json.adjustment_amount item.child_item.adjustment_amount
    end
  end
  if item.parent_item
    json.parent do
      json.id item.parent_item.id
      json.name item.parent_item.name
      json.from_account_id item.parent_item.from_account_id
      json.to_account_id item.parent_item.to_account_id
      json.action_date item.parent_item.action_date
      json.amount item.parent_item.amount
      json.adjustment_amount item.parent_item.adjustment_amount
    end
  end
end
