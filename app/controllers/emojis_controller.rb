class EmojisController < ApplicationController
  before_filter :required_login

  def index
    if params[:form_id].blank?
      redirect_js_to(current_entries_url) and return
    end
  end
end
