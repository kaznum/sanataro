# -*- coding: utf-8 -*-
class Api::AccountsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_filter :required_login
  respond_to :json

  def index
    accounts = {}
    %w(bankings incomes expenses).each do |type|
      accounts[type.to_sym] = Rails.cache.fetch("user_#{@user.id}_api_accounts_#{type}") { @user.send(type.to_s.to_sym).map{|a| {id: a.id, name: a.name, bgcolor: a.bgcolor }}}
    end
    render json: accounts.to_json
  end
end
