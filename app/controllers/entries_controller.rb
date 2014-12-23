class EntriesController < ApplicationController
  include Common::Entries
  before_action :required_login

  def index
    super
    case
    when params[:remaining]
      template = 'index_for_remaining'
    when !params[:filter_account_id].nil?
      # when "No filter" is selected, params[:filter_...] is ""
      # so it should not use blank?/present? in the condition
      template = "index_with_filter_account_id"
    when @tag.present? || @keyword.present?
      template = 'index_with_tag_keyword'
    when @mark.present?
      template = 'index_with_mark'
    else
      @new_item = Item.new { |item| item.action_date = _default_action_date(displaying_month) }
      template = 'index'
    end
    render template
  rescue ArgumentError # in case the date in params has invalid format
    respond_to do |format|
      format.js {  redirect_js_to current_entries_url }
      format.html {  redirect_to current_entries_url }
    end
  end

  def new
    if params[:entry_type] == 'simple'
      _new_simple
    else
      _new_entry(params[:entry_type])
    end
  end

  def show
    _xhr_action("warning") {
      super
    }
  end

  def edit
    _xhr_action("warning") {
      @item = @user.items.find(params[:id])
    }
  end

  def destroy
    _xhr_action("warning") {
      super
      render "destroy", locals: { item: @item, deleted_ids: @deleted_item_ids, updated_items: @updated_items }
    }
  end

  def create
    _xhr_action("warning") {
      super

      if params[:only_add]
        render "create_item_simple", locals: { item: @item }
      else
        @items = get_items(month: displaying_month)
        template = @item.adjustment? ? "create_adjustment" : "create_item"
        render template, locals: { item: @item, items: @items, updated_item_ids: @updated_item_ids }
      end
    }
  end

  def update
    _xhr_action("item_warning_#{params[:id]}") {
      super
      items = get_items(month: displaying_month)
      render "update", locals: { item: @item, items: items, updated_item_ids: @updated_item_ids }
    }
  end

  private

  # this method is called when a link in the field of adding regular item or adjustment.
  # which switches forms each other.
  def _new_entry(entry_type)
    action_date = _get_date_by_specific_year_and_month_or_today(params[:year], params[:month])
    item_class = entry_type == 'adjustment' ? Adjustment : GeneralItem
    @item = item_class.new(action_date: action_date)
    render "new"
  end

  def _new_simple
    @data = {
      authenticity_token: form_authenticity_token,
      year: today.year,
      month: today.month,
      day: today.day,
      from_accounts: from_accounts,
      to_accounts: to_accounts,
    }

    render 'new_simple', layout: false
  end

  def _xhr_action(warning_selector, &block)
    block.call
  rescue ActiveRecord::RecordNotFound
    redirect_js_to current_entries_url
  rescue InvalidDate
    render_js_error id: warning_selector, default_message: t("error.date_is_invalid")
  rescue SyntaxError
    render_js_error id: warning_selector, default_message: t("error.amount_is_invalid")
  rescue ActiveRecord::RecordInvalid => ex
    render_js_error(id: warning_selector, errors: ex.record.errors.full_messages, default_message: t("error.input_is_invalid"))
  end
end

