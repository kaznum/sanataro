Fabricator(:credit_relation) do
  credit_account_id 10
  payment_account_id 20
  settlement_day 99
  payment_month 2
  payment_day 20
  after_build { |item| item.user_id = 1 }
end
