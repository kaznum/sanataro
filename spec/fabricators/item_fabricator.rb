Fabricator(:item) do
  user_id 1
  name "ItemName"
  from_account_id 1
  to_account_id 3
  amount 1000
  action_date "2011-11-01"
  adjustment false
  adjustment_amount 0
  confirmation_required false
end
