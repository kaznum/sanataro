# -*- coding: utf-8 -*-
class StatController < ApplicationController
  before_filter :required_login

  TOTAL_TYPES = ["total", "income_total", "outgo_total"]

  def index
    redirect_to current_entries_url
  end

  #
  # line graph for yearly balance of a account
  #
  def show_yearly_bs_graph
    if params[:year].blank? || params[:month].blank? || (params[:type] != 'total' && params[:account_id].blank? )
      redirect_rjs_to login_url
      return
    end
    
    display_year = params[:year].to_i
    display_month = params[:month].to_i

    account_id = params[:account_id].to_i
    type = params[:type]

    if type == 'total'
      @url = url_for(:action=>"yearly_bs_graph", :type=>type, :year => display_year, :month => display_month)
      @graph_id = 'total'
    else
      @url = url_for(:action=>"yearly_bs_graph", :account_id=>account_id, :year => display_year, :month => display_month)
      @graph_id = account_id.to_s
    end
  end

  #
  # generate bs line graph 
  #
  def yearly_bs_graph
    
    if params[:year].blank? || params[:month].blank? 
      redirect_to login_url
      return
    end
    
    type = params[:type]
    if type != "total"
      if params[:account_id].blank?
        redirect_to login_url
        return
      end
      account_id = params[:account_id].to_i
    end
    
    date = Date.new(params[:year].to_i, params[:month].to_i)

    graph_since = date.months_ago(11).beginning_of_month
    graph_to = date.beginning_of_month

    if type == 'total'
      account = Account.new(name: "資本合計")
    else
      account = @user.accounts.find_by_id(account_id)
    end

    if account.nil?
      redirect_to login_url
      return
    end
    if type == "total"

      bank_accounts = @user.accounts.where(:account_type => 'account')
      bank_ids = []
      bank_accounts.each do |ba|
        bank_ids.push ba.id
      end
      initial_total = @user.monthly_profit_losses.where("month < ? and account_id IN (?)", graph_since, bank_ids).sum(:amount)
      tmp_pls = @user.monthly_profit_losses.where("month between ? and ? and account_id IN (?)", graph_since, graph_to, bank_ids).order(:month)
      pls = []
      total_pl = nil
      tmp_pls.each do |tpl|
        if total_pl.nil? || total_pl.month != tpl.month
          pls.push total_pl unless total_pl.nil?
          total_pl = MonthlyProfitLoss.new
          total_pl.month = tpl.month
          total_pl.amount = tpl.amount
        else
          total_pl.amount += tpl.amount
        end
      end
      # ループの最後は配列にpushされていないので、ここで追加
      pls.push total_pl

    else
      initial_total = @user.monthly_profit_losses.scoped_by_account_id(account_id).where("month < ?", graph_since).sum(:amount)
      pls = @user.monthly_profit_losses.scoped_by_month(graph_since..graph_to).scoped_by_account_id(account_id).order(:month)
    end

    amounts = []
    pl = nil
    total = initial_total.nil? ? 0 : initial_total

    (0..11).each do |i|

      pl = pls.shift if pl.nil?

      if pl.nil?
        amounts.push total
      else
        if pl.month == graph_since.months_since(i).beginning_of_month
          total += pl.amount
          amounts.push total
          pl = nil
        else
          amounts.push total
        end
      end
    end
    
    title = "#{account.name} の推移"

    g = generate_yearly_graph(title, account, amounts, graph_since)
    send_data g.to_blob, :type => 'image/png', :disposition => 'inline', :stream => false

  end

  #
  # line graph for yearly profit loss of a account
  #
  def show_yearly_pl_graph
    if params[:year].blank? || params[:month].blank? ||
        ((not (params[:type] == 'total' ||
               params[:type] == 'income_total' ||
               params[:type] == 'outgo_total')
          ) && params[:account_id].blank?)
      redirect_rjs_to login_url
      return
    end

    account_id = params[:account_id].to_i
    type = params[:type]

    if type == 'total' || type == 'income_total' || type == 'outgo_total'
      @graph_id = type
      @url = url_for(:action => "yearly_pl_graph",
                      :type => type,
                      :year => params[:year].to_i,
                      :month => params[:month].to_i)
    else
      @graph_id = account_id
      @url = url_for(:action=>"yearly_pl_graph",
                      :account_id=>account_id,
                      :year => params[:year].to_i,
                      :month => params[:month].to_i)
    end
  end

  #
  # pl line graph
  #
  def yearly_pl_graph
    if params[:year].blank? || params[:month].blank?
        redirect_to login_url
        return
    end

    type = params[:type]
    unless TOTAL_TYPES.include?(type)
      if params[:account_id].blank?
        redirect_to login_url
        return
      end
      account_id = params[:account_id].to_i
    end

    account = _find_or_new_virtual_account(@user, type, account_id)
    if account.nil?
      redirect_to login_url
      return
    end

    date = Date.new(params[:year].to_i, params[:month].to_i)
    amounts = get_monthly_amounts_for_a_year_to(date, type, account_id)

    title = "#{account.name} の推移"
    graph_since = date.months_ago(11).beginning_of_month
    g = generate_yearly_graph(title, account, amounts, graph_since)
    send_data g.to_blob, :type => 'image/png', :disposition => 'inline', :stream => false
  end
  
  #
  # yearly line graph
  #
  def generate_yearly_graph(title, account, amounts, from)
    g = Gruff::Line.new '400x200'
    g.font = GRAPH_FONT
    g.title = title

    label0 = from.year.to_s + "/" + from.month.to_s
    label1 = from.months_since(3).strftime("%Y/%m")
    label2 = from.months_since(6).strftime("%Y/%m")
    label3 = from.months_since(9).strftime("%Y/%m")
    label4 = from.months_since(12).strftime("%Y/%m")

    g.data account.name, amounts
    g.labels = {0 => label0, 3 => label1, 6 => label2, 9=> label3, 12 => label4}
    g
  end

  private
  def get_monthly_amounts_for_a_year_to(date, type, account_id)
    graph_since = date.months_ago(11).beginning_of_month
    graph_to = date.beginning_of_month

    if TOTAL_TYPES.include?(type)
      pls = total_typed_account_profit_losses(type, graph_since, graph_to)
    else
      pls = @user.monthly_profit_losses.scoped_by_month(graph_since..graph_to).scoped_by_account_id(account_id).order(:month)
    end
    
    amounts = []
    pl = nil
    (0..11).each do |i|
      pl = pls.shift if pl.nil?
      if pl.nil?
        amounts << 0
      else
        if graph_since.months_since(i).beginning_of_month == pl.month.beginning_of_month
          amounts << pl.amount.abs
          pl = nil
        else
          amounts << 0
        end
      end
    end

    amounts
  end

  def total_typed_account_profit_losses(type, since, to)
    account_ids = all_account_ids_by_total_type(type)
    pls = account_ids.size == 0 ? [] : @user.monthly_profit_losses.scoped_by_month(since..to).scoped_by_account_id(account_ids).order(:month)

    total_pls = []
    total_pl = nil
    pls.each do |tpl|
      if total_pl && tpl.month != total_pl.month
        # ループの一番最初以外で、monthが異なる場合
        total_pls << total_pl
      end
      total_pl = MonthlyProfitLoss.new(:user_id => tpl.user_id, :month => tpl.month, :amount => 0)

      if type == "income_total"
        # 不明支出以外
        unless tpl.account_id == -1 && tpl.amount > 0
          # amountの正負はincome、outgoにかかわらず不定であるため、absは使わない
          total_pl.amount += tpl.amount * (-1)
        end
      elsif type == "outgo_total"
        # 不明収入以外
        unless tpl.account_id == -1 && tpl.amount < 0
          # amountの正負はincome、outgoにかかわらず不定であるため、absは使わない
          total_pl.amount += tpl.amount
        end
      else # type == total
        # すべての正負を含めたtotalを計算するので、absは使わない
        total_pl.amount += tpl.amount
      end
    end
    total_pls << total_pl unless total_pl.nil? # ループの最後だけ配列に登録されていないため、ループの後に登録
    total_pls
  end
  
  def all_account_ids_by_total_type(type)
    case type
    when "total"
      accounts = @user.accounts.find_all_by_account_type('account')
    when "income_total"
      accounts = @user.accounts.find_all_by_account_type('income')
    when "outgo_total"
      accounts = @user.accounts.find_all_by_account_type('outgo')
    end
    account_ids = accounts.map{|a| a.id }
    account_ids << -1 if type == "income_total" || type == "outgo_total"
    account_ids
  end

  def _find_or_new_virtual_account(user, type, account_id)
    if account_id == -1
      account = Account.new(id: -1, name: _('Unknown'), account_type: 'unknown')
    elsif type == "total"
      account = Account.new(name: _('Benefit of the month'), account_type: 'total')
    elsif type == "income_total"
      account = Account.new(name: _('Total of Income'), account_type: 'income_total')
    elsif type == "outgo_total"
      account = Account.new(name: _('Total of Outgo'), account_type: 'outgo_total')
    else
      account = user.accounts.find_by_id(account_id)
    end
  end

end
