# -*- coding: utf-8 -*-
class EntriesController < ApplicationController
  before_filter :required_login
  before_filter :set_categorized_accounts, :only => [:index, :create, :update, :destroy, :new, :edit, :show]
  before_filter :_redirect_to_login_by_js_if_id_is_blank, :only => [:update]

  def index
    @tag = params[:tag]
    @mark = params[:mark]

    case
    when params[:remaining]
      _index_for_remaining(displaying_month, @tag, @mark)
    when !params[:filter_account_id].nil?
      _index_with_filter_account_id
    when @tag.present?
      _index_with_tag(@tag)
    when @mark.present?
      _index_with_mark(@mark)
    else
      _index_plain(displaying_month)
    end
  rescue # 日付が不正の場合がある
    respond_to do |format|
      format.js {  redirect_js_to current_entries_url }
      format.html {  redirect_to current_entries_url }
    end
  end

  def _index_with_filter_account_id
    _set_filter_account_id_to_session_from_params
    @items = _get_items(displaying_month)
    render "index_with_filter_account_id"
  end

  def _index_with_tag(tag)
    @items = _get_items(nil, false, tag, nil)
    render 'index_with_tag'
  end

  def _index_with_mark(mark)
    @items = _get_items(nil, false, nil, mark)
    render 'index_with_mark'
  end

  def _default_action_date(month_to_display)
    month_to_display == today.beginning_of_month ? today : month_to_display
  end

  def _set_filter_account_id_to_session_from_params
    account_id = params[:filter_account_id].to_i
    session[:filter_account_id] = account_id == 0 ? nil : account_id
  end

  def _index_plain(month_to_display)
    @items = _get_items(month_to_display)
    @new_item = Item.new { |item| item.action_date = _default_action_date(month_to_display) }
  end

  def new
    case params[:entry_type]
    when 'simple'
      _new_simple
    when 'adjustment'
      _new_adjustment
    else
      _new_entry
    end
  end

  def create
    _xhr_action("warning") {
      if params[:entry_type] == 'adjustment'
        _create_adjustment
      else
        _create_entry
      end
    }
  end

  def _xhr_action(warning_selector, &block)
    block.call
  rescue ActiveRecord::RecordNotFound => ex
    redirect_js_to current_entries_url
  rescue InvalidDate
    render_js_error :id => warning_selector, :default_message => t("error.date_is_invalid")
  rescue SyntaxError
    render_js_error :id => warning_selector, :default_message => t("error.amount_is_invalid")
  rescue ActiveRecord::RecordInvalid => ex
    render_js_error(:id => warning_selector, :errors => ex.error_messages, :default_message => t("error.input_is_invalid"))
  end

  def update
    _xhr_action("item_warning_#{params[:id]}") {
      id = params[:id].to_i
      if params[:entry_type] == 'adjustment'
        args = {
          to_account_id: params[:to],
          adjustment_amount: Item.calc_amount(params[:adjustment_amount])
        }
      else
        args = {
          name: params[:item_name],
          from_account_id: params[:from],
          to_account_id: params[:to],
          amount: Item.calc_amount(params[:amount])
        }
      end

      args.merge!({ confirmation_required: params[:confirmation_required],
                    tag_list: params[:tag_list],
                    action_date: _get_action_date_from_params })

      item, updated_item_ids, deleted_item_ids = Teller.update_entry(@user, id, args)
      items = _get_items(displaying_month)
      render "update", locals: { item: item, items: items, updated_item_ids: updated_item_ids }
    }
  end

  def _redirect_to_login_by_js_if_id_is_blank
    if params[:id].blank?
      redirect_js_to login_url
      return false
    end
    return true
  end

  def destroy
    _xhr_action("warning") {
      item = @user.items.find(params[:id])
      _destroy_item(item)
    }
  end

  def edit
    _xhr_action("warning") {
      @item = @user.items.find(params[:id])
    }
  end

  def show
    _xhr_action("warning") {
      @item = @user.items.find(params[:id])
    }
  end

  private

  # this method is called when a link in the field of adding adjustment
  # which switches to the regular item new entry input.
  def _new_entry
    action_date = _get_date_by_specific_year_and_month_or_today(params[:year], params[:month])
    @item = Item.new(action_date: action_date)
    render "add_item"
  end

  # this method is called when a link in the field of adding regular item
  # which switches to the adjustment item new entry input.
  def _new_adjustment
    @action_date = _get_date_by_specific_year_and_month_or_today(params[:year], params[:month])
    render "add_adjustment"
  end

  def _get_date_by_specific_year_and_month_or_today(year, month)
    action_date = nil
    begin
      unless today.beginning_of_month == Date.new(year.to_i, month.to_i).beginning_of_month
        action_date = Date.new(year.to_i, month.to_i)
      end
    rescue ArgumentError => ex
      # do nothing
      # return default value (Today) as below.
    end
    action_date || today
  end

  def _create_adjustment
    action_date = _get_action_date_from_params

    to_account_id = params[:to].to_i
    adjustment_amount = Item.calc_amount(params[:adjustment_amount])

    Item.transaction do
      prev_adj = @user.items.find_by_to_account_id_and_action_date_and_adjustment(to_account_id, action_date, true)
      _do_delete_item(prev_adj.id) if prev_adj

      item, updated_item_ids =
        Teller.create_entry(user: @user, action_date: action_date, name: 'Adjustment',
                            from_account_id: -1, to_account_id: to_account_id,
                            adjustment: true, tag_list: params[:tag_list],
                            adjustment_amount: adjustment_amount)
      @items = _get_items(displaying_month)
      updated_item_ids << item.try(:id)

      render "create_adjustment", locals: { item: item, items: @items, updated_item_ids: updated_item_ids.reject(&:nil?).uniq }

    end
  end

  def _create_entry
    Item.transaction do
      item, affected_item_ids =
        Teller.create_entry(:user => @user, :name => params[:item_name],
                            :from_account_id => params[:from], :to_account_id => params[:to],
                            :amount => Item.calc_amount(params[:amount]),
                            :action_date => _get_action_date_from_params,
                            :confirmation_required => params[:confirmation_required],
                            :tag_list => params[:tag_list])

      if params[:only_add]
        render "create_item_simple", locals: { item: item }
      else
        @items = _get_items(displaying_month)
        affected_item_ids << item.try(:id)
        render "create_item", locals: { item: item, items: @items, updated_item_ids: affected_item_ids.reject(&:nil?).uniq }
      end
    end
  end

  def _get_action_date_from_params
    Date.parse(params[:action_date])
  rescue
    raise InvalidDate
  end

  def _destroy_item(item)
    Item.transaction do
      result_of_delete = _do_delete_item(item.id)
      updated_items = result_of_delete[0].map {|id| @user.items.find_by_id(id)}.reject(&:nil?)
      render "destroy", locals: { item: item, deleted_ids: result_of_delete[1], updated_items: updated_items }
    end
  end

  def _new_simple
    @data = {
      :authenticity_token => form_authenticity_token,
      :year => today.year,
      :month => today.month,
      :day => today.day,
      :from_accounts => from_accounts,
      :to_accounts => to_accounts,
    }

    render 'new_simple', :layout => false
  end

  def from_accounts
    from_or_to_accounts(:from_accounts)
  end

  def to_accounts
    from_or_to_accounts(:to_accounts)
  end

  def from_or_to_accounts(from_or_to = :from_accounts)
    @__cat_accounts__ ||= @user.get_categorized_accounts

    # FIXME
    # html escape should be done in Views.
    @__cat_accounts__[from_or_to].map {|a| { :value => a[1], :text => ERB::Util.html_escape(a[0]) } }
  end

  #
  # 支出一覧の「すべて表示」をクリックした場合の処理
  #
  def _index_for_remaining(month, tag=nil, mark=nil)
    if tag.present? || mark.present?
      month_to_display = nil
    else
      month_to_display = month.beginning_of_month
    end

    @items = _get_items(month_to_display, true, tag, mark)
    render 'index_for_remaining'
  end

  #
  # get items from db
  # remain  true: 非表示の部分を取得
  #
  def _get_items(month, remain=false, tag=nil, mark=nil)
    if month.present?
      from_date = month.beginning_of_month
      to_date = month.end_of_month
    end
    Item.find_partial(@user, from_date, to_date,
                      { :filter_account_id => session[:filter_account_id],
                        :remain=>remain, :tag => tag, :mark => mark})
  end

  def _do_delete_item(item_id)
    Teller.destroy_entry(@user, item_id)
  end
end

class InvalidDate < Exception
end
