module ChartHelper
  def toggle_legend_link(chart_selector)
    link_to t('link.toggle_label'), '#', onclick: "$('#{chart_selector} > .legend').toggle();return false;", class: 'trivial_link'
  end
end
