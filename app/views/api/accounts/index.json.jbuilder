json.accounts do
  json.bankings accounts[:bankings] do |account|
    json.(account, :id, :name, :bgcolor)
  end
  json.incomes accounts[:incomes] do |account|
    json.(account, :id, :name, :bgcolor)
  end
  json.expenses accounts[:expenses] do |account|
    json.(account, :id, :name, :bgcolor)
  end
end
