# frozen_string_literal: true

json.entries do
  json.array!(items) do |item|
    json.partial! 'entry', item: item
  end
end
