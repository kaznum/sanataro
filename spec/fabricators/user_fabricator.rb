Fabricator(:user) do
  password "samplepass"
  active true
  email "xxxx@example.com"
  confirmation "xxxxxxxxxx"
  after_build { |u| u.login = 'sample' }
end
