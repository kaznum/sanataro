# frozen_string_literal: true

Fabricator(:general_item) do
  name 'ItemName'
  from_account_id 1
  to_account_id 3
  amount 1000
  action_date '2011-11-01'
  adjustment_amount 0
  confirmation_required false
  user_id 1
end
