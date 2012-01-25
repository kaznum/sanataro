# -*- coding: utf-8 -*-
class EntriesController < ApplicationController
  before_filter :required_login
  before_filter :set_separated_accounts, :only => [:index, :create, :update, :destroy, :new, :edit, :show]
  before_filter :_redirect_to_login_by_rjs_if_id_is_blank, :only => [:update]
  
  def index
    @tag = params[:tag]
    @mark = params[:mark]

    @display_year_month = _date_to_display(params[:year], params[:month])

    case
    when params[:remaining]
      _index_for_remaining(params[:year].to_i, params[:month].to_i, @tag, @mark)
    when !params[:filter_account_id].nil?
      _index_with_filter_account_id
    when @tag.present?
      _index_with_tag(@tag)
    when @mark.present?
      _index_with_mark(@mark)
    else
      _index_plain(@display_year_month)
    end
  rescue # 日付が不正の場合がある
    respond_to do |format|
      format.js {  redirect_rjs_to current_entries_url }
      format.html {  redirect_to current_entries_url }
    end
  end
  
  def _index_with_filter_account_id
    _set_filter_account_id_to_session_from_params
    @items = _get_items(@display_year_month.year, @display_year_month.month)
    render "index_with_filter_account_id", :handlers => [:rjs]
  end
  
  def _index_with_tag(tag)
    @items = _get_items(nil, nil, false, tag, nil)
    render ('index_with_tag')
  end
  
  def _index_with_mark(mark)
    @items = _get_items(nil, nil, false, nil, mark)
    render ('index_with_mark')
  end
  
  def _default_action_date(month_to_display)
    month_to_display == today.beginning_of_month ? today : month_to_display
  end
  
  def _set_filter_account_id_to_session_from_params
    account_id = params[:filter_account_id].to_i
    session[:filter_account_id] = account_id == 0 ? nil : account_id
  end
      
  def _date_to_display(year, month)
    year.present? && month.present? ? Date.new(year.to_i, month.to_i) : today.beginning_of_month
  end
    
  
  def _index_plain(month_to_display)
    @items = _get_items(month_to_display.year, month_to_display.month)
    @new_item = Item.new { |item| item.action_date = _default_action_date(month_to_display) }
  end

  #
  # 支出、収入の登録入力
  #
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
    if params[:entry_type] == 'adjustment'
      _create_adjustment
    else
      _create_entry
    end
  end
  
  def update
    if params[:entry_type] == 'adjustment'
      _update_adjustment
    else
      _update_item
    end

  end

  def _redirect_to_login_by_rjs_if_id_is_blank
    if params[:id].blank?
      redirect_rjs_to login_url
      return false
    end
    return true
  end
  
  def destroy
    item = @user.items.find(params[:id])
    _destroy_item(item)
  rescue ActiveRecord::RecordNotFound => ex
    url = params[:id].blank? ? login_url : entries_url(today.year, today.month)
    redirect_rjs_to url
  end

  def _destroy_item(item)
    if item.is_adjustment?
      _destroy_adjustment(item)
    else
      _destroy_regular_item(item)
    end
  end
  #
  # アイテムの編集領域の表示
  #
  def edit
    @item = @user.items.find(params[:id])
  rescue ActiveRecord::RecordNotFound => ex
    redirect_rjs_to entries_url(:year => today.year, :month => today.month)
  end
  
  #
  # replace an input field with a regular text
  #
  def show
    @item = @user.items.find(params[:id])
  rescue ActiveRecord::RecordNotFound => ex
    redirect_rjs_to current_entries_url
  end


  private
  #### PRIVATE ###########
  # 収支の登録
  def _new_entry
    item = Item.new
    if params[:year].blank? || params[:month].blank? || today.beginning_of_month == Date.new(params[:year].to_i, params[:month].to_i)
      item.action_date = today
    else
      item.action_date = Date.new(params[:year].to_i, params[:month].to_i)
    end

    @item = item
    render "add_item", :handlers => [:rjs]
  end

  #
  # 残高調整の登録入力
  #
  def _new_adjustment
    @action_date = _get_date_by_specific_year_and_month_or_today(params[:year], params[:month])
    render "add_adjustment", :handlers => [:rjs]
  end
  
  def _get_date_by_specific_year_and_month_or_today(year, month)
    action_date = nil
    begin
      unless today.beginning_of_month == Date.new(year.to_i, month.to_i).beginning_of_month
        action_date = Date.new(year.to_i, month.to_i)
      end
    rescue ArgumentError => ex
    end
    action_date || today
  end
  
  #
  # exec adding adjustment
  #
  def _create_adjustment
    item = nil
    display_year = params[:year].to_i
    display_month = params[:month].to_i
    year, month, day = _get_action_year_month_day_from_params
    action_date = Date.new(year,month,day)
    to_account_id = CommonUtil.remove_comma(params[:to]).to_i
    adjustment_amount = Item.calc_amount(params[:adjustment_amount])
    
    Item.transaction do
      # すでに同日かつ同account_idの残高調整が存在しないかチェックし、存在する場合は削除する
      prev_adj = @user.items.find_by_to_account_id_and_action_date_and_is_adjustment(to_account_id, action_date, true)
      _do_delete_item(prev_adj.id) if prev_adj
      
      asset = @user.accounts.asset(@user, to_account_id, action_date)
      amount = adjustment_amount - asset
      
      item, ignored =
        Teller.create_entry(user: @user, action_date: action_date, name: 'Adjustment',
                            from_account_id: -1, to_account_id: to_account_id,
                            is_adjustment: true, tag_list: params[:tag_list],
                            adjustment_amount: adjustment_amount, amount: amount)
      @item = item
      
      if item.action_date.beginning_of_month == Date.new(display_year, display_month)
        items = _get_items(item.action_date.year, item.action_date.month)
      end

      render :update do |page|

        page[:warning].set_style :color => 'blue'
        page.replace_html :warning, _('Item was added successfully.') + ' ' + item.action_date.strftime("%Y/%m/%d") + ' ' + _('Adjustment') + ' ' + CommonUtil.separate_by_comma(item.adjustment_amount) + _('yen')
        if item.action_date.beginning_of_month == Date.new(display_year, display_month)
          page.replace_html :items, ''
          items.each do |it|
            page.insert_html :bottom, :items, partial: 'item', locals: { event_item: it }
          end
          page.insert_html :bottom, :items, :partial=>'remains_link'
          page.select('#item_' + item.id.to_s + ' div').each do |etty|
            etty.visual_effect :highlight, :duration => HIGHLIGHT_DURATION
          end
        end
      end
    end
  rescue SyntaxError
    render_rjs_error :id => "warning", :default_message => _("Amount is invalid.")
  rescue ActiveRecord::RecordInvalid => ex
    render_rjs_error(:id => "warning", :errors => ex.message.split(",").map(&:strip), :default_message => _('Input value is incorrect'))
  end

  #
  # exec adding item.
  #
  def _create_entry
    item = nil
    Item.transaction do
      year, month, day = _get_action_year_month_day_from_params
      name  = params[:item_name]
      amount = 0
      only_add = params[:only_add]
      from  = params[:from].to_i
      to  = params[:to].to_i
      confirmation_required = params[:confirmation_required]
      tag_list = params[:tag_list]
      unless only_add
        display_year = params[:year].to_i
        display_month = params[:month].to_i
        @display_year_month = Date.new(display_year, display_month)
      end
      # could raise SyntaxError because of :amount has an statement.
      amount = Item.calc_amount(params[:amount])

      item, affected_items =
        Teller.create_entry(:user => @user,
                            :name => name,
                            :from_account_id => from.to_i,
                            :to_account_id => to.to_i,
                            :amount => amount,
                            :action_date => Date.new(year,month,day),
                            :confirmation_required => confirmation_required,
                            :tag_list => tag_list)
      # 以下、表示処理
      item_month = Date.new(year, month, 1)
      # displaying page from here
      @renderer_queues ||= []
      if only_add
        @renderer_queues += renderer_queues_for_create_entry_simple(item)
      else
        if item_month == @display_year_month
          @items = _get_items(item_month.year, item_month.month)
        end
        
        @renderer_queues += renderer_queues_for_create_entry(item, @items)
      end
    end # transaction
    render "common/rjs_queue_renderer", :handlers => [:rjs]
  rescue SyntaxError
    render_rjs_error :id => "warning", :default_message => _("Amount is invalid.")
  rescue ActiveRecord::RecordInvalid => ex
    render_rjs_error(:id => "warning", :errors => ex.message.split(",").map(&:strip), :default_message => _('Input value is incorrect'))
  end

  def renderer_queues_for_create_entry_simple(item)
    ques = []
    ques += renderer_queues_for_info(:warning, _('Item was added successfully.') + ' ' + item.action_date.strftime("%Y/%m/%d") + ' ' + item.name + ' ' + CommonUtil.separate_by_comma(item.amount) + _('yen'))
    ques += renderer_queues_for_plain("$('do_add_item').item_name.value = ''")
    ques += renderer_queues_for_plain("$('do_add_item').amount.value = ''")
    ques += renderer_queues_for_clear_content(:candidates)
    ques
  end
  
  def renderer_queues_for_create_entry(item, items)
    ques = []
    ques += renderer_queues_for_info(:warning,
                                     _('Item was added successfully.') +
                                     ' ' +
                                     item.action_date.strftime("%Y/%m/%d") +
                                     ' ' +
                                     item.name +
                                     ' ' +
                                     CommonUtil.separate_by_comma(item.amount) +
                                     _('yen')) +
      renderer_queues_for_plain("$('do_add_item').item_name.value = ''") +
      renderer_queues_for_plain("$('do_add_item').amount.value = ''") +
      renderer_queues_for_plain("$('do_add_item').tag_list.value = ''")
    if item.action_date.beginning_of_month == @display_year_month
      ques += renderer_queues_for_clear_content(:items)
      ques += renderer_queues_for_all_items(:items, items)
      ques += renderer_queues_for_appending_to_bottom(:items, :partial => 'remains_link')
      ques += renderer_queues_for_highlight("item_#{item.id}", "#item_#{item.id} div")
      ques += renderer_queues_for_clear_content(:candidates)
    end
    ques
  end

  def renderer_queues_for_all_items(id, items)
    ques = []
    items.each do |it|
      ques += renderer_queues_for_appending_to_bottom(id, :partial => "entries/item", :locals => { :event_item => it })
    end
    ques
  end

  def renderer_queues_for_highlight(id, selector=nil)
    highlight_command = { :command => :visual_effect, :effect => :highlight, :id => id, :duration => HIGHLIGHT_DURATION }
    if selector
      [{ :command => :select, :id => selector, :blocks => [highlight_command]}]
    else
      [highlight_command]
    end
  end
  
  def _get_action_year_month_day_from_params
    year  = params[:action_year].to_i
    month = params[:action_month].to_i
    day = params[:action_day].to_i
    return [year, month, day]
  end

  # adjustmentの削除
  def _destroy_adjustment(item)
    display_year = params[:year].to_i
    display_month = params[:month].to_i
    
    Item.transaction do
      deleted_item, f_adj, adj = _do_delete_item(item.id)[:itself]

      # 表示処理
      @renderer_queues = []
      @renderer_queues += renderer_queues_for_destroy_adjustment(item, adj,display_year, display_month)
      render 'common/rjs_queue_renderer', :handlers => [:rjs]
    end # transaction
  end

  
  def renderer_queues_for_destroy_adjustment(item, adj,display_year, display_month)
    ques = []
    ques += renderer_queues_for_info(:warning, _('Item was deleted successfully.') + ' ' +
                                     item.action_date.strftime("%Y/%m/%d") + ' ' +
                                     _('Adjustment') + ' ' +
                                     CommonUtil.separate_by_comma(item.adjustment_amount) + _('yen'))
    ques += renderer_queues_for_removing("item_#{item.id}")

    unless  (adj.nil? ||
             adj.action_date <= Date.new(display_year, display_month) ||
             adj.action_date >= Date.new(display_year, display_month).end_of_month)
      ques += renderer_queues_for_replace("item_#{adj.id}",
                                          :partial => 'entries/item',
                                          :locals => { :event_item => adj })
    end
    ques
  end
  
  def renderer_queues_for_clear_content(id)
    [{ :command => :replace_html, :id => id, :body => '' }]
  end

  def renderer_queues_for_info(id, message)
    ques = []
    ques << { :command => :set_style, :id => id, :color => 'blue' }
    ques << { :command => :replace_html, :id => id, :body => message }
    ques
  end
  
  def renderer_queues_for_plain(body)
    [ { :command => :plain, :body => body }]
  end
  

  def renderer_queues_for_removing(id, delay=nil)
    ques = []
    ques << { :command => :visual_effect, :effect => :fade, :id => id, :duration => FADE_DURATION  }
    ques << { :command => :remove, :id => id, :delay => 3 }
    ques
  end

  def renderer_queues_for_replace(id, *attr)
    ques = []
    ques << { :command => :replace, :id => id }.merge(*attr)
    ques += renderer_queues_for_highlight(id)
    ques
  end
  
  def renderer_queues_for_appending_to_bottom(id, *attr)
    ques = []
    ques << { :command => :insert_html, :id => id, :position => :bottom }.merge(*attr)
    ques
  end
  

  #
  # アイテムの削除実行
  #
  def _destroy_regular_item(item)
    display_year = params[:year].to_i
    display_month = params[:month].to_i

    Item.transaction do
      result_of_delete = _do_delete_item(item.id)
      deleted_item, from_adj_item, to_adj_item = result_of_delete[:itself]
      deleted_child_item, from_adj_child, to_adj_child = result_of_delete[:child]

      # 以下、表示処理
      # 残高調整の更新も行われた場合は、一覧全体を再描画する。
      render :update do |page|

        page[:warning].set_style :color => 'blue'
        page.replace_html :warning, _('Item was deleted successfully.') + ' ' +
          item.action_date.strftime("%Y/%m/%d") + ' ' + item.name + ' ' +
          CommonUtil.separate_by_comma(item.amount) + _('yen')

        page.visual_effect :fade, "item_#{item.id}", :duration => FADE_DURATION
        page.delay(3.seconds) do
          page.remove "item_#{item.id}"
        end
        if from_adj_item &&
            from_adj_item.action_date >= Date.new(display_year, display_month) &&
            from_adj_item.action_date <= Date.new(display_year, display_month).end_of_month
          page.replace "item_#{from_adj_item.id}", partial: 'item', locals: { event_item: from_adj_item }
          page.visual_effect :highlight, "item_#{from_adj_item.id}", :duration => HIGHLIGHT_DURATION
        end

        if to_adj_item &&
            to_adj_item.action_date >= Date.new(display_year, display_month) &&
            to_adj_item.action_date <= Date.new(display_year, display_month).end_of_month
          page.replace "item_#{to_adj_item.id}", partial: 'item', locals: { event_item: to_adj_item }
          page.visual_effect :highlight, "item_#{to_adj_item.id}", :duration => HIGHLIGHT_DURATION

        end

        #クレジットカード処理
        if deleted_child_item && deleted_child_item.action_date.strftime("%Y/%m") == item.action_date.strftime("%Y/%m")
          # 表示されていない可能性があるため、Collection Proxyを利用する
          page.select("#item_#{deleted_child_item.id}").each do |etty|
            etty.visual_effect :fade, :duration => FADE_DURATION
          end
          page.select("#item_#{deleted_child_item.id}").each do |etty|
            page.delay(3.seconds) do
              etty.remove
            end
          end
        end
      end
    end # transaction
  end
  
  #
  # 残高調整の変更実行処理
  #
  def _update_adjustment
    item_id = params[:id].to_i
    item = @user.items.find_by_id(item_id)

    old_action_date = item.action_date
    old_amount = item.amount
    old_from_id = item.from_account_id
    old_to_id = item.to_account_id
    old_adjustment_amount = item.adjustment_amount
    old_tag_list = item.tag_list

    item.year, item.month, item.day = _get_action_year_month_day_from_params
    item.to_account_id  = params[:to].to_i
    item.tag_list = params[:tag_list]
    item.user_id = item.user.id

    display_year = params[:year].to_i
    display_month = params[:month].to_i
    @display_year_month = Date.new(display_year, display_month)
    # could raise SyntaxError
    item.adjustment_amount = Item.calc_amount(params[:adjustment_amount])

    raise ActiveRecord::RecordInvalid.new(item) unless item.valid?

    Item.transaction do
      # 未来の残高調整を行なう。
      # 残高調整のため、一度、amountを0にする。
      item.amount = 0
      item.save!
      MonthlyProfitLoss.correct(@user, -1, old_action_date.beginning_of_month)
      MonthlyProfitLoss.correct(@user, old_to_id, old_action_date.beginning_of_month)
      old_future_adj = Item.update_future_balance(@user, old_action_date, old_to_id, item.id)
      
      # amountの算出
      asset = @user.accounts.asset(@user, item.to_account_id, item.action_date, item.id)
      item.amount = item.adjustment_amount - asset
      item.save!
      @item = item
      MonthlyProfitLoss.correct(@user, -1, item.action_date.beginning_of_month)
      MonthlyProfitLoss.correct(@user, item.to_account_id, item.action_date.beginning_of_month)
      
      # 新account_idで、未来に残高調整が存在する場合の調整
      new_future_adj = Item.update_future_balance(@user, item.action_date, item.to_account_id, item.id)

      # 表示処理
      unless old_action_date == item.action_date &&
          ((old_future_adj.nil? && new_future_adj.nil?)||
           old_future_adj && new_future_adj &&
           old_future_adj.id == new_future_adj.id &&
           old_future_adj.to_account_id == new_future_adj.to_account_id )
        items = _get_items(display_year, display_month)
      end

      render :update do |page|
        #日付に変更がなく、未来のadjustmentが存在しないか
        #もしくは、存在するが、to_account_idに変更がなく、
        # 表示中の月と同一月の場合
        #
        if old_action_date == item.action_date &&
            ((old_future_adj.nil? && new_future_adj.nil?)||
             old_future_adj && new_future_adj &&
             old_future_adj.id == new_future_adj.id &&
             old_future_adj.to_account_id == new_future_adj.to_account_id )

          page.replace "item_#{item.id}", partial: 'item', locals: { event_item: item }

          if new_future_adj && new_future_adj.action_date <= Date.new(display_year, display_month).end_of_month &&
              old_future_adj.action_date.beginning_of_month == Date.new(display_year, display_month)
            page.replace "item_#{new_future_adj.id}", partial: 'item', locals: { event_item: new_future_adj }
          end
        else
          page.replace_html :items,''
          items.each do |it|
            page.insert_html :bottom, :items, partial: 'item', locals: { event_item: it }
          end
          page.insert_html :bottom, :items, :partial => 'remains_link'

        end

        # 変更された未来のadjustmentのハイライト表示
        selectors = []
        if old_future_adj && new_future_adj
          if old_future_adj.id == new_future_adj.id # to_account_idがかわっていない
            selectors << "#item_#{old_future_adj.id} div"
          else
            selectors << "#item_#{old_future_adj.id} div"
            selectors << "#item_#{new_future_adj.id} div"
          end
        elsif old_future_adj
          selectors << "#item_#{old_future_adj.id} div"
        elsif new_future_adj
          selectors << "#item_#{new_future_adj.id} div"
        end
        selectors << "#item_#{item.id} div"

        selectors.each do |s|
          page.select(s).each do |etty|
            etty.visual_effect :highlight, :duration => HIGHLIGHT_DURATION
          end
        end

        page[:warning].set_style :color => 'blue'
        page.replace_html :warning, _('Item was changed successfully.') +
          ' ' + item.action_date.strftime("%Y/%m/%d") + ' ' + _('Adjustment') + ' ' +
          CommonUtil.separate_by_comma(item.adjustment_amount) + _('yen')
      end
    end
  rescue SyntaxError
    render_rjs_error(:id => "warning", :errors => nil, :default_message => _("Amount is invalid."))
  rescue ActiveRecord::RecordInvalid => ex
    render_rjs_error :id => "item_warning_#{item.id}", :errors => ex.message.split(",").map(&:strip), :default_message =>  _('Input value is incorrect.')
  end

  #
  # Store item info to DB
  #
  def _update_item
    item_id = params[:id].to_i
    @item = item = @user.items.find(item_id)
    old_action_date = item.action_date
    old_amount = item.amount
    old_from_id = item.from_account_id
    old_to_id = item.to_account_id
    old_adjustment_amount = item.adjustment_amount
    old_child_id = item.child_item.try(:id)
    old_confirmation_required = item.confirmation_required?
    old_tag_list = item.tag_list

    # 新規値の登録
    item.is_adjustment = false
    item.name = params[:item_name]
    item.year, item.month, item.day = _get_action_year_month_day_from_params
    item.from_account_id  = params[:from].to_i
    item.to_account_id  = params[:to].to_i
    item.confirmation_required = params[:confirmation_required]
    item.tag_list = params[:tag_list]
    item.user_id = item.user.id
    
    display_year = params[:year].to_i
    display_month = params[:month].to_i
    @display_year_month = display_from_date = Date.new(display_year, display_month)
    display_to_date = display_from_date.end_of_month
    # could raise SyntaxError
    item.amount = Item.calc_amount(params[:amount])

    Item.transaction do
      item.save!
      MonthlyProfitLoss.correct(@user, old_from_id, old_action_date.beginning_of_month)
      MonthlyProfitLoss.correct(@user, old_to_id, old_action_date.beginning_of_month)
      MonthlyProfitLoss.correct(@user, item.from_account_id, item.action_date.beginning_of_month)
      MonthlyProfitLoss.correct(@user, item.to_account_id, item.action_date.beginning_of_month)
      
      old_from_item_adj = Item.update_future_balance(@user, old_action_date,
                                                     old_from_id, item.id)
      old_to_item_adj = Item.update_future_balance(@user, old_action_date,
                                                   old_to_id, item.id)
      from_item_adj = Item.update_future_balance(@user, item.action_date,
                                                 item.from_account_id, item.id)
      to_item_adj = Item.update_future_balance(@user, item.action_date,
                                               item.to_account_id, item.id)

      # クレジットカードの処理
      # 一旦古い情報を削除し、再度追加の必要がある場合のみ追加する
      deleted_child_item, from_adj_credit, to_adj_credit = (_do_delete_item(old_child_id))[:child] if old_child_id
      cr = @user.credit_relations.find_by_credit_account_id(item.from_account_id)
      if cr.nil?
        payment_account_id = nil
        credit_item = nil
      else
        payment_account_id = cr.payment_account_id
      end
      if payment_account_id
        paydate = _credit_due_date(item.from_account_id, item.action_date)

        credit_item, ignored =
          Teller.create_entry(user: @user, name: item.name,
                              from_account_id: payment_account_id, to_account_id: item.from_account_id,
                              amount: item.amount,
                              year: paydate.year, month: paydate.month, day: paydate.day,
                              parent_item: item)
      end
      item.reload

      # クレジットカード処理終了

      # 以下、表示処理
      #日付に変更がない場合は、並び順が変わらないため、当該アイテムのみ表示を変更する。
      
      if (old_action_date == item.action_date &&
          (old_from_item_adj.nil? ||
           old_from_item_adj.action_date < display_from_date || old_from_item_adj.action_date > display_to_date) &&
          (old_to_item_adj.nil? ||
           old_to_item_adj.action_date < display_from_date || old_to_item_adj.action_date > display_to_date ) &&
          (from_item_adj.nil? ||
           from_item_adj.action_date < display_from_date || from_item_adj.action_date > display_to_date ) &&
          (to_item_adj.nil? ||
           to_item_adj.action_date < display_from_date || to_item_adj.action_date > display_to_date ))

        render :update do |page|
          page.replace 'item_' + item.id.to_s, partial: 'item', locals: { event_item: item }
          page[:warning].set_style :color => 'blue'
          page.replace_html :warning, _('Item was changed successfully.') +
            ' ' + item.action_date.strftime("%Y/%m/%d") + ' ' + item.name + ' ' +
            CommonUtil.separate_by_comma(item.amount) + _('yen')

          if item.action_date >= display_from_date && item.action_date <= display_to_date
            page.select('#item_' + item.id.to_s + ' div').each do |etty|
              etty.visual_effect :highlight, :duration => HIGHLIGHT_DURATION
            end
          end
        end
      else # action_dateが変わり、なおかつ、未来の残高調整が同月に存在するばあい
        @items = _get_items(display_year, display_month)
        render :update do |page|
          page.replace_html :items, ''
          @items.each do |it|
            page.insert_html :bottom, :items, partial: 'item', locals: { event_item: it }
          end
          page.insert_html :bottom, :items, :partial=>'remains_link'

          page[:warning].set_style :color=>'blue'
          page.replace_html :warning, _('Item was changed successfully.') + ' ' + item.action_date.strftime("%Y/%m/%d") + ' ' + item.name + ' ' + CommonUtil.separate_by_comma(item.amount) + _('yen')
          if item.action_date >= display_from_date && item.action_date <= display_to_date
            page.select('#item_' + item.id.to_s + ' div').each do |etty|
              etty.visual_effect :highlight, :duration => HIGHLIGHT_DURATION
            end
          end
        end
      end
    end
    
  rescue SyntaxError
    render_rjs_error :id => "item_warning_#{@item.id}", :errors => nil, :default_message =>  _("Amount is invalid.")
  rescue ActiveRecord::RecordInvalid => ex
    render_rjs_error(:id => 'item_warning_' + @item.id.to_s,
                     :errors => ex.message.split(",").map(&:strip),
                     :default_message => _('Input value is incorrect.'))
  end

  #
  # 入力機能のみ表示(iPhone等でアクセスした場合)
  #
  def _new_simple
    from_accounts = Array.new
    separated_accounts = @user.get_separated_accounts
    separated_accounts[:from_accounts].each do |a|
      v = { :value => a[1], :text => ERB::Util.html_escape(a[0]) }
      from_accounts.push v
    end
    to_accounts = Array.new
    separated_accounts[:to_accounts].each do |a|
      v = { :value => a[1], :text => ERB::Util.html_escape(a[0]) }
      to_accounts.push v
    end

    @data = {
      :authenticity_token => form_authenticity_token,
      :year => today.year,
      :month => today.month,
      :day => today.day,
      :from_accounts => from_accounts,
      :to_accounts => to_accounts,
    }

    render :action => 'new_simple', :layout => false
  end
  
  
  #
  # 支出一覧の「すべて表示」をクリックした場合の処理
  #
  def _index_for_remaining(year=nil, month=nil, tag=nil, mark=nil)
    if tag.present? || mark.present?
      y = m = nil
    else
      y, m = year, month
    end
    
    @items = _get_items(y, m, true, tag, mark)
    render 'index_for_remaining', :handlers => [:rjs]
  end
  
  #
  # get items from db
  # remain  true: 非表示の部分を取得
  #
  def _get_items(year, month, remain=false, tag=nil, mark=nil)
    if year.present? && month.present? 
      from_date = Date.new(year,month)
      to_date = from_date.end_of_month
    end
    return Item.find_partial(@user, from_date, to_date,
                             { :filter_account_id => session[:filter_account_id],
                               :remain=>remain, :tag => tag, :mark => mark})
  end

  def _do_delete_item(item_id)
    Teller.destroy_entry(@user, item_id)
  end

  # カード引き落とし日を算出する
  # params: account_id (カードのアカウントID)
  # params: date (決済日)
  def _credit_due_date(account_id, date)
    @user.accounts.where(id: account_id).first.credit_due_date(date)
  end
end
