# frozen_string_literal: true

require 'spec_helper'

describe '/settings/accounts/edit', type: :view do
  fixtures :users, :accounts

  context 'when enough params,' do
    before do
      assign :account, accounts(:bank1)
    end

    describe 'no error' do
      it { expect { render 'edit' }.not_to raise_error }
    end
  end
end
