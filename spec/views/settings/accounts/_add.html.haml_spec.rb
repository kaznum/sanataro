require 'spec_helper'

describe '/settings/accounts/_add', type: :view do
  fixtures :users, :accounts

  context 'when enough params,' do
    before do
      assign :accounts, [accounts(:bank1), accounts(:bank11)]
      assign :type, :banking
    end

    describe 'no error' do
      it { expect { render partial: 'add' }.not_to raise_error }
    end

    describe 'body' do
      subject { render partial: 'add' }
      it { is_expected.to match /<input[^>]+type="hidden"[^>]+name="type"[^>]+value="banking"[^>]+>/ }
    end
  end
end
