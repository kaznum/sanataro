# frozen_string_literal: true
require 'spec_helper'

describe '/account_statuses/show', type: :view do
  fixtures :all

  before(:each) do
    assigns[:account_statuses] = @account_statuses = {
      incomes: [[accounts(:income2), 100]],
      expenses: [[accounts(:expense3), 200]],
      bankings: [[accounts(:bank1), 300]]
    }
    render
  end

  subject { rendered }
  it { is_expected.to match(/\$\("#digest_body"\).html\(/) }
  it { is_expected.to match(/\$\("#digest_title"\).html\(/) }
end
