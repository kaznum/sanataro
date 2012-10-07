Fabricator(:banking) do
  name "AccountName"
  active true
  order_no 1
  after_build { |item| item.user_id = 1 }
end

