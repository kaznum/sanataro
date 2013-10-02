require 'spec_helper'

describe "/settings/accounts/_add" do
  fixtures :users, :accounts

  context "when enough params," do
    before do
      assign :accounts, [accounts(:bank1), accounts(:bank11)]
      assign :type, :banking
    end

    describe "no error" do
      it { expect { render partial: 'add' }.not_to raise_error }
    end

    describe "body" do
      subject { render partial: 'add' }
      it { should match /<input[^>]+name="type"[^>]+type="hidden"[^>]+value="banking"[^>]+>/ }
    end
  end
end

