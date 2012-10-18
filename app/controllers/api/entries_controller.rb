class Api::EntriesController < ApplicationController
  include Api
  include Common::Entries
  respond_to :json

  def index
    super
    render locals: { items: @items }
  rescue ArgumentError
    render nothing: true, status: :not_acceptable
  end

  def show
    _json_action do
      super
      render locals: { item: @item }
    end
  end

  def create
    _json_action do
      super
      render locals: { item: @item, updated_item_ids: @updated_item_ids }, status: :created, :location => api_entries_url(@item.id)
    end
  end

  def update
    _json_action do
      super
      render locals: { item: @item, updated_item_ids: @updated_item_ids }, status: :ok
    end
  end

  def destroy
    _json_action do
      super
      render locals: { item: @item, updated_item_ids: @updated_item_ids, deleted_item_ids: @deleted_item_ids }, status: :ok
    end
  end

  private
  def _json_action(&block)
    block.call
  rescue SyntaxError
    errors = [t("error.amount_is_invalid")]
    render json: { errors: errors }.to_json, status: :not_acceptable
  rescue InvalidDate # in case the date in params has invalid format
    errors = [t("error.date_is_invalid")]
    render json: { errors: errors }.to_json, status: :not_acceptable
  rescue ActiveRecord::RecordNotFound
    render nothing: true, status: :not_found
  rescue ActiveRecord::RecordInvalid => ex
    errors = ex.error_messages
    render json: { errors: errors }.to_json, status: :not_acceptable
  end
end

