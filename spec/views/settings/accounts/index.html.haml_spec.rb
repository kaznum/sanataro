require 'spec_helper'

describe "/settings/accounts/index" do
  fixtures :users, :accounts

  context "when enough params," do
    before do
      assign :accounts, [accounts(:bank1), accounts(:bank11)]
      assign :type, :banking
    end

    it { expect{ render }.not_to raise_error }
  end
end

