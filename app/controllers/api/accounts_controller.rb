# -*- coding: utf-8 -*-
class Api::AccountsController < ApplicationController
  include Api
  include ActionView::Helpers::NumberHelper
  respond_to :json

  def index
    accounts = Rails.cache.fetch("user_#{@user.id}_api_accounts") {
      accts = []
      %w(bankings incomes expenses).each do |type|
        accts +=  @user.send(type.to_s.to_sym)
      end
      accts
    }
    render locals: {accounts: accounts}
  end
end
