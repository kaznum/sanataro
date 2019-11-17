module EntriesHelper
  def link_to_confirmation_required(item_id, required, options = {})
    label = required ? icon_confirmation : icon_no_confirmation
    css_class = required ? 'item_confirmation_required' : 'item_confirmation_not_required'
    tag = options[:tag]
    mark = options[:mark]
    keyword = options[:keyword]
    if tag
      url = tag_entry_confirmation_required_path(tag, item_id, confirmation_required: !required)
    elsif mark
      url = mark_entry_confirmation_required_path(mark, item_id, confirmation_required: !required)
    elsif keyword
      url = keyword_entry_confirmation_required_path(keyword, item_id, confirmation_required: !required)
    else
      url = entry_confirmation_required_path(item_id, confirmation_required: !required)
    end

    link_to label, url, remote: true, method: :put, class: css_class
  end

  def relative_path(item_id)
    item = @user.items.find(item_id)
    relative = item.parent_item || item.child_item
    relative ? entries_path(year: relative.action_date.year, month: relative.action_date.month, anchor: "item_#{relative.id}") : nil
  end

  def link_to_edit(item, enabled = true)
    if enabled
      link_to icon_edit, edit_entry_path(item.action_date.year, item.action_date.month, item.id), remote: true, method: :get, class: 'edit_link'
    else
      icon_edit(enabled)
    end
  end

  def link_to_destroy(item, enabled = true)
    if enabled
      link_to icon_destroy, entry_path(item.action_date.year, item.action_date.month, item.id), remote: true, method: :delete, data: { confirm: t('message.delete_really') }
    else
      icon_destroy(enabled)
    end
  end

  def link_to_show(item, enabled = true)
    if enabled
      link_to icon_show, entries_path(item.action_date.year, item.action_date.month, anchor: "item_#{item.id}"), class: 'show_link'
    else
      icon_show(enabled)
    end
  end

  def icon_confirmation
    '<i class="icon-star item_confirmation_required"></i>'.html_safe
  end

  def icon_no_confirmation
    '<i class="icon-star-empty item_confirmation_not_required"></i>'.html_safe
  end

  def link_to_tags(item)
    if item.tags.size > 0
      ('[' + item.tags.sort { |a, b| a.name <=> b.name }.map { |tag| link_to_tag(tag) }.join(' ') + ']').html_safe
    else
      ''
    end
  end

  def item_row_class(item)
    row_class = ''
    if item.adjustment?
      row_class = 'item_adjustment'
    elsif item.parent_id
      row_class = 'item_move'
    elsif @user.income_ids.include?(item.from_account_id)
      row_class = 'item_income'
    elsif @user.banking_ids.include?(item.from_account_id) && @user.banking_ids.include?(item.to_account_id)
      row_class = 'item_move'
    end
    row_class
  end

  def item_row_name(item)
    if item.adjustment?
      item_name = t('label.adjustment').decorate + ' ' + number_to_currency(item.adjustment_amount)
      item_name.html_safe
    elsif item.parent_id
      link_body = "#{l(item.parent_item.action_date, format: :short)} #{item.parent_item.name.decorate}".html_safe
      item_name = "#{t('entries.item.deposit')} (#{link_to link_body, relative_path(item.id)})".html_safe
    elsif item.child_item
      link_body = "#{l(item.child_item.action_date, format: :short)} #{t('entries.item.deposit')}".html_safe
      item_name = "#{item.name.decorate} (#{link_to link_body, relative_path(item.id)})".html_safe
    else
      item_name = item.name.decorate
    end

    item_name
  end

  def item_row_confirmation_required(item, tag, mark, keyword)
    if item.adjustment?
      confirmation_required = ''
    elsif item.parent_id
      confirmation_required = link_to_confirmation_required(item.id, item.parent_item.confirmation_required?, tag: tag, mark: mark, keyword: keyword)
    else
      confirmation_required = link_to_confirmation_required(item.id, item.confirmation_required?, tag: tag, mark: mark, keyword: keyword)
    end

    confirmation_required
  end

  def item_row_from_account(item)
    if item.adjustment?
      from_account = item.amount < 0 ? colored_account_name(item.to_account_id) : '(' + t('label.adjustment') + ')'
    else
      from_account = colored_account_name(item.from_account_id)
    end
    from_account
  end

  def item_row_to_account(item)
    if item.adjustment?
      to_account = item.amount >= 0 ? colored_account_name(item.to_account_id) :
        '(' + t('label.adjustment') + ')'
    else
      to_account = colored_account_name(item.to_account_id)
    end
    to_account
  end

  def item_row_twitter_button(item)
    if item.adjustment? || item.parent_id
      ''
    else
      tweet_button(item)
    end
  end

  def item_row_operation(item, only_show = false)
    if only_show
      link_to_show(item)
    else
      (item_row_twitter_button(item) +
       link_to_edit(item) +
       link_to_destroy(item, item.parent_id.blank?)).html_safe
    end
  end
end
