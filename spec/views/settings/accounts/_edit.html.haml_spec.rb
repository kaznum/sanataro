require 'spec_helper'

describe "/settings/accounts/_edit" do
  fixtures :users, :accounts

  context "when enough params," do
    before do
      assign :account, accounts(:bank1)
    end

    describe "no error" do
      it { expect { render partial: 'edit' }.not_to raise_error }
    end

    describe "body" do
      subject { render partial: 'edit' }
      it { should match /<input[^>]+name="account_name"[^>]+type="text"[^>]+value="#{accounts(:bank1).name}"[^>]+>/ }
      it { should match /<input[^>]+name="order_no"[^>]+type="text"[^>]+value="#{accounts(:bank1).order_no}"[^>]+>/ }
      it { should match /<input[^>]+name="bgcolor"[^>]+type="hidden"[^>]+value="#ffffff"[^>]+>/ }
    end
  end
end

