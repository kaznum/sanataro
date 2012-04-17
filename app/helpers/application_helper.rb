# -*- coding: utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include MonthlistHelper
  #
  # 口座名に背景色を付与する
  #
  def colored_account_name(account_id)
    color = @separated_accounts[:account_bgcolors][account_id]
    name = @separated_accounts[:all_accounts][account_id]
    color ? "<span style='background-color: ##{h(color)}; padding-right:2px;padding-left:2px;'>#{h(name)}</span>".html_safe : h(name)
  end

  def calendar_from(user)
    from_month =  user.monthly_profit_losses.where("amount <> 0").minimum('month') || Date.today.beginning_of_month
    from_month.months_ago(2).beginning_of_month
  end

  def calendar_to(user)
    to_month = user.monthly_profit_losses.where("amount <> 0").maximum('month') || Date.today.beginning_of_month
    to_month.months_since(2).beginning_of_month
  end

  def link_to_tag(tag)
    link_to(tag.name, tag_entries_path(:tag => tag.name), :rel => 'tag')
  end

  def today
    @view_cached_today ||= Date.today
  end

  def highlight(selector)
    "$('#{selector}').effect('highlight', {color: '#{ Settings.effect.highlight.color }'}, #{ Settings.effect.highlight.duration });"
  end

  def fadeout_and_remove(selector)
    "$('#{selector}').fadeOut(#{Settings.effect.fade.duration}, function() {$('#{selector}').remove();});"
  end
end

