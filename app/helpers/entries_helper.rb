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

    link_to label, url, remote: true, method: :put, :class => css_class
  end

  def relative_path(item_id)
    item = @user.items.find(item_id)
    relative = item.parent_item || item.child_item
    relative ? entries_path(year: relative.action_date.year, month: relative.action_date.month, anchor: "item_#{relative.id}") : nil
  end

  def link_to_edit(event_item, enabled = true)
    if enabled
      link_to icon_edit, edit_entry_path(event_item.action_date.year, event_item.action_date.month, event_item.id), :remote => true, :method => :get, :class => "edit_link"
    else
      icon_edit(enabled)
    end
  end

  def link_to_destroy(event_item, enabled = true)
    if enabled
      link_to icon_destroy, entry_path(event_item.action_date.year, event_item.action_date.month, event_item.id), :remote => true, :method => :delete, :data => { :confirm => t("message.delete_really") }
    else
      icon_destroy(enabled)
    end
  end

  def link_to_show(event_item, enabled = true)
    if enabled
      link_to icon_show, entries_path(event_item.action_date.year, event_item.action_date.month, anchor: "item_#{event_item.id}"), :class => "show_link"
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
end
