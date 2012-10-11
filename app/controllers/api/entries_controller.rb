class Api::EntriesController < ApplicationController
  include Common::Entries
  respond_to :json

  def index
    super
    respond_with @items.to_json(:include => [:parent_item, :child_item])
  end
end

