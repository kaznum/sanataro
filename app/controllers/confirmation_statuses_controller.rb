# frozen_string_literal: true

class ConfirmationStatusesController < ApplicationController
  before_action :required_login
  def show
    @entries = @user.items.confirmation_required.order_of_entries
  end
end
