require 'spec_helper'

describe '/settings/accounts/_edit', :type => :view do
  fixtures :users, :accounts

  context 'when enough params,' do
    before do
      assign :account, accounts(:bank1)
    end

    describe 'no error' do
      it { expect { render partial: 'edit' }.not_to raise_error }
    end

    describe 'body' do
      subject { render partial: 'edit' }
      it { is_expected.to match /<input[^>]+type="text"[^>]+name="account_name"[^>]+value="#{accounts(:bank1).name}"[^>]+>/ }
      it { is_expected.to match /<input[^>]+type="text"[^>]+name="order_no"[^>]+value="#{accounts(:bank1).order_no}"[^>]+>/ }
      it { is_expected.to match /<input[^>]+type="hidden"[^>]+name="bgcolor"[^>]+value="#ffffff"[^>]+>/ }
    end
  end
end
