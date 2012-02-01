class ConfirmationRequiredsController < ApplicationController
  before_filter :required_login
  before_filter :set_categorized_accounts
  def update
    return if _redirect_to_current_entries_if_params_are_invalid
    
    @entry = Item.find(params[:entry_id])
    @entry.update_confirmation_required_of_self_or_parent(params[:confirmation_required])
  rescue ActiveRecord::RecordNotFound => ex
    redirect_js_to current_entries_url
  end
  
  private
  
  def _redirect_to_current_entries_if_params_are_invalid
    if params[:confirmation_required].nil?
      redirect_js_to current_entries_url
      return true
    end
    return false
  end


end
