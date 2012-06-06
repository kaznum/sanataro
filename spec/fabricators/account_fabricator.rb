Fabricator(:account) do
  name "AccountName"
  active true
  account_type "account"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

Fabricator(:outgo, from: :account) do
  name "Outgo Name"
  active true
  account_type "outgo"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

Fabricator(:income, from: :account) do
  name "Income Name"
  active true
  account_type "income"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

