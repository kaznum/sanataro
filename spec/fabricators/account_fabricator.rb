Fabricator(:account) do
  user_id 1
  name "AccountName"
  active true
  account_type "account"
  order_no 1
end

Fabricator(:outgo, from: :account) do
  user_id 1
  name "Outgo Name"
  active true
  account_type "outgo"
  order_no 1
end

Fabricator(:income, from: :account) do
  user_id 1
  name "Income Name"
  active true
  account_type "income"
  order_no 1
end

