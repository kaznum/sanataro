Fabricator(:banking) do
  name "AccountName"
  active true
  type "Banking"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

Fabricator(:expense, from: :account) do
  name "Outgo Name"
  active true
  type "Expense"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

Fabricator(:income, from: :account) do
  name "Income Name"
  active true
  type "Income"
  order_no 1
  after_build { |item| item.user_id = 1 }
end

