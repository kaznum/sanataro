module MonthlistHelper
  def monthlist(from_year, from_month, to_year, to_month, selected_year, selected_month, current_action = 'items')
    out = "<div class='monthlist'><div class='years'>" + from_year.upto(to_year).map { |y| link_to(y, "#year_#{y}", { class: (y == selected_year ? "selected" : "unselected") }) }.join + "</div>"
    year = from_year
    month = from_month
    out += "<div class='year_#{year}' style='display: #{year == selected_year ? 'block;' : 'none;'}'>"
    year.upto(to_year) do |y|
      if y == to_year
        out += month.upto(to_month).map { |m|
          css_class = (selected_year == y && selected_month == m) ? "selected" : "unselected"
          link_to(m.to_s, { action: current_action, year: y, month: m }, { class: css_class })
        }.join
        out += "</div></div>"
      else
        out += month.upto(12).map { |m|
          css_class = selected_year == y && selected_month == m ? "selected" : "unselected"
          link_to(m.to_s, { action: current_action, year: y, month: m }, { class: css_class })
        }.join
        month = 1
        out += "</div><div class='year_#{y + 1}' style='display: #{y + 1 == selected_year ? 'block;' : 'none;'}'>"
      end
    end
    out.html_safe
  end
end
