# frozen_string_literal: true

json.entry do
  json.partial! 'entry', item: item
end
json.updated_entry_ids updated_item_ids
json.deleted_item_ids deleted_item_ids
