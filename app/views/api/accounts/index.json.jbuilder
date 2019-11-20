# frozen_string_literal: true

json.accounts do
  json.array!(accounts) do |account|
    json.call(account, :id, :name, :bgcolor, :type)
  end
end
