require 'spec_helper'

describe "/settings/accounts/_show" do
  fixtures :users, :accounts

  context "when enough params," do
    describe "no error" do
      it { expect { render partial: 'show', locals: { account: accounts(:bank1) } }.not_to raise_error }
    end

    describe "body" do
      subject { render partial: 'show', locals: { account: accounts(:bank1) } }
      it { should match %r(<a[^>]+href="/settings/accounts/#{accounts(:bank1).id}/edit"[^>]*>) }
    end
  end
end

