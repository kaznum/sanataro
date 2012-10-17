json.accounts do
  json.array!(accounts) do |account|
    json.(account, :id, :name, :bgcolor, :type)
  end
end
