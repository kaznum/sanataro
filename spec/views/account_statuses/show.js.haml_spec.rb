require 'spec_helper'

describe "/account_statuses/show" do
  fixtures :all

  before(:each) do
    assigns[:account_statuses] = @account_statuses = {
      incomes: [[accounts(:income2), 100]],
      expenses: [[accounts(:expense3), 200]],
      bankings: [[accounts(:bank1), 300]]
    }
    render
  end

  subject {  rendered }
  it { should =~ /\$\("#digest_body"\).html\(/ }
  it { should =~ /\$\("#digest_title"\).html\(/ }
end

