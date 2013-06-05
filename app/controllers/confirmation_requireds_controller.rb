class ConfirmationRequiredsController < ApplicationController
  before_action :required_login
  before_action :_redirect_to_current_entries_if_params_are_invalid!

  def update
    @tag = params[:tag]
    @mark = params[:mark]
    @keyword = params[:keyword]

    @entry = Item.find(params[:entry_id])
    @entry.update_confirmation_required_of_self_or_parent(params[:confirmation_required])
  rescue ActiveRecord::RecordNotFound
    redirect_js_to current_entries_url
  end

  private

  def _redirect_to_current_entries_if_params_are_invalid!
    if params[:confirmation_required].nil?
      redirect_js_to current_entries_url
      return false
    end
    return true
  end
end
