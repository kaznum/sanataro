# -*- coding: utf-8 -*-
class EntryCandidatesController < ApplicationController
  before_action :required_login

  def index
    partial_name = params[:item_name]

    if partial_name.blank?
      render text: ''
      return
    end

    items_table = @user.items.arel_table

    #
    # In fact, order("max_id desc").limit(5) is better.
    # But SQL Server doesn't have limit and offset clauses.
    # Arel and the method `replace_limit_offset!' in SqlServerReplaceLimitOffset module
    # (in activerecord-jdbc-adapter gem) generates SQL to support them and it works well
    # for simple cases. But SQL Server cannot evaluate the generated query if order('...')
    # includes some aliased column names which are defined in select clause with 'AS ...'
    #
    # The following statement generates a complex query and using with `limit(5)` hits
    # the above problem, so it is conditional depending on whether MsSQL or not.
    # The current code can cost so much high because lots of records could be gotten
    # under MsSQL.
    # This may be better to be replaced with another way to implement.
    #
    items = @user.general_items
      .where(items_table[:name].matches("%#{partial_name}%"))
      .where(parent_id: nil)
      .group('name, from_account_id, to_account_id, amount')
      .select('max(id) as max_id, name, from_account_id, to_account_id, amount').order("max_id desc")
    items = ActiveRecord::Base.connection.adapter_name == 'MsSQL' ? items[0..4] : items.limit(5)
    render partial: 'candidate', collection: items
  end
end






