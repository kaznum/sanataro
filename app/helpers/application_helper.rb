# -*- coding: utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	include MonthlistHelper
  extend ERB::DefMethod
  def_erb_method('render_item(event_item)', "#{Rails.root.to_s}/app/views/entries/_item.html.erb")

  #
  # 口座名に背景色を付与する
  #
  def colored_account_name(account_id)
    color = @separated_accounts[:account_bgcolors][account_id]
    name = @separated_accounts[:all_accounts][account_id]
    if color.nil?
      return h(name)
    else
      return "<span style='background-color: ##{h(color)}; padding-right:2px;padding-left:2px;'>#{h(name)}</span>".html_safe
    end
  end

  def calendar_from(user)
    from_month =  user.monthly_profit_losses.minimum('month') || Date.today.beginning_of_month
    return from_month.months_ago(2).beginning_of_month
  end

  def calendar_to(user)
    to_month = user.monthly_profit_losses.maximum('month') || Date.today.beginning_of_month
    return to_month.months_since(2).beginning_of_month
  end
  
  def link_to_tag(tag)
    link_to(tag.name, tag_entries_path(:tag => tag.name), :rel => 'tag')
  end

  def today
    @view_cached_today ||= Date.today
  end

  if RUBY_VERSION >= "1.9"
    module ActionView
      class OutputBuffer < ActiveSupport::SafeBuffer
        def <<(value)
          super(value.to_s.force_encoding('UTF-8'))
        end
        alias :append= :<<
      end
    end
  end
end
