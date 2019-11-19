# frozen_string_literal: true

Fabricator(:user) do
  password 'samplepass'
  active true
  email 'xxxx@example.com'
  confirmation 'xxxxxxxxxx'
  login 'sample'
end
