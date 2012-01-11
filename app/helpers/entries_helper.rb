module EntriesHelper
  def render_item(event_item)
    render partial: 'item', locals: { event_item: event_item }
  end
end
