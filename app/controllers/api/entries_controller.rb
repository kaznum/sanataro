class Api::EntriesController < ApplicationController
  include Common::Entries
  respond_to :json

  JSON_ATTRS_FOR_ONLY = [:id, :name, :from_account_id, :to_account_id, :action_date, :tag_list, :amount, :adjustment_amount]
  JSON_INCLUDES = [{parent_item: { only: JSON_ATTRS_FOR_ONLY }}, { child_item: { only: JSON_ATTRS_FOR_ONLY }}]
  AS_JSON_PARAMS = {only: JSON_ATTRS_FOR_ONLY, include: JSON_INCLUDES}

  def index
    super
  rescue ArgumentError
    render nothing: true, status: :not_acceptable
  end

  def show
    _json_action do
      super
    end
  end

  def create
    _json_action do
      super
      render json: { item: @item.as_json(AS_JSON_PARAMS), updated_item_ids: @updated_item_ids }.to_json, status: :created, :location => api_entries_url(@item.id)
    end
  end

  def update
    _json_action do
      super
      render json: { item: @item.as_json(AS_JSON_PARAMS), updated_item_ids: @updated_items }.to_json, status: :ok
    end
  end

  def destroy
    _json_action do
      super
      render json: { item: @item.as_json(AS_JSON_PARAMS), updated_item_ids: @updated_items.map(&:id), deleted_item_ids: @deleted_item_ids }.to_json, status: :ok
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

