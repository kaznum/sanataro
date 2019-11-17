# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include MonthlistHelper
  #
  # 口座名に背景色を付与する
  #
  def colored_account_name(account_id)
    color = @user.account_bgcolors[account_id]
    name = @user.all_accounts[account_id]
    color ? "<span class='label' style='background-color: ##{h(color)};'>#{h(name)}</span>".html_safe : h(name)
  end

  def calendar_from(user)
    from_month = user.monthly_profit_losses.where.not(amount: 0).minimum('month') || Date.today.beginning_of_month
    from_month.months_ago(2).beginning_of_month
  end

  def calendar_to(user)
    to_month = user.monthly_profit_losses.where.not(amount: 0).maximum('month') || Date.today.beginning_of_month
    to_month.months_since(2).beginning_of_month
  end

  def link_to_tag(tag)
    link_to(tag.name, tag_entries_path(tag: tag.name), rel: 'tag')
  end

  def today
    @view_cached_today ||= Date.today
  end

  def highlight(selector)
    "$('#{selector}').effect('highlight', {color: '#{GlobalSettings.effect.highlight.color}'}, #{GlobalSettings.effect.highlight.duration});".html_safe
  end

  def fadeout_and_remove(selector)
    "$('#{selector}').fadeOut(#{GlobalSettings.effect.fade.duration}, function() {$('#{selector}').remove();});".html_safe
  end

  def icon_show(enabled = true)
    additional = enabled ? '' : 'disabled'
    "<i class=\"icon-share-alt show_icon #{additional}\"></i>".html_safe
  end

  def icon_edit(enabled = true)
    additional = enabled ? '' : 'disabled'
    "<i class=\"icon-pencil edit_icon #{additional}\"></i>".html_safe
  end

  def icon_destroy(enabled = true)
    additional = enabled ? '' : 'disabled'
    "<i class=\"icon-trash destroy_icon #{additional}\"></i>".html_safe
  end
end
