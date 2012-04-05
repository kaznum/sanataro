module MonthlistHelper
  def monthlist(from_year, from_month, to_year, to_month, selected_year, selected_month, current_action='items')
    year = from_year
    month = from_month
    out = "<div id='year_#{year}'>#{year}|"
    year.upto(to_year) do |y|
      if y == to_year
        month.upto(to_month) do |m|
          out += link_to_unless(selected_year == y && selected_month == m, m.to_s, :action => current_action, :year => y, :month=>m) + "|"
        end
        out += "</div>"
      else
        month.upto(12) do |m|
          out += link_to_unless(selected_year == y && selected_month == m, m.to_s, :action => current_action, :year => y, :month=>m) + "|"
        end
        month = 1
        out += "</div><div id='year_#{y + 1}'>#{y + 1}|"
      end  
    end
    out.html_safe
  end
end
