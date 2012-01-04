# -*- coding: utf-8 -*-
class ConfirmationStatusesController < ApplicationController
  before_filter :required_login
  def show
    @entries = @user.items.confirmation_required.order_for_entries_list
  end
  
end
