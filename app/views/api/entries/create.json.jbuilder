json.entry do
  json.partial! 'entry', item: item
end
json.updated_entry_ids updated_item_ids
