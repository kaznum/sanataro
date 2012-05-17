# -*- coding: utf-8 -*-
module ChartHelper
  def toggle_legend_link(chart_selector)
    link_to_function t('link.toggle_label'), "$('#{chart_selector} > .legend').toggle()", class: "trivial_link"
  end
end
