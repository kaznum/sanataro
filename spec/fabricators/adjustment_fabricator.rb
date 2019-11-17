Fabricator(:adjustment) do
  name 'ItemName'
  from_account_id(-1)
  to_account_id 1
  amount 1000
  action_date '2011-12-01'
  adjustment_amount 3000
  confirmation_required false
  user_id 1
end
