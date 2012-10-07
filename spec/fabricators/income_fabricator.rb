Fabricator(:income) do
  name "Income Name"
  active true
  order_no 1
  after_build { |item| item.user_id = 1 }
end

