# frozen_string_literal: true
class Api::AccountsController < ApplicationController
  include Api::Auth
  include ActionView::Helpers::NumberHelper
  respond_to :json

  def index
    accounts = Rails.cache.fetch("user_#{@user.id}_api_accounts") do
      accts = []
      %w(bankings incomes expenses).each do |type|
        accts +=  @user.send(type.to_s.to_sym)
      end
      accts
    end
    render locals: { accounts: accounts }
  end
end
