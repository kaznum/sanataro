module MonthlistHelper
  #
  # display months' list(link)
  #
  def monthlist(from_year, from_month, to_year, to_month, selected_year, selected_month, current_action='items')
    year = from_year
    month = from_month
    out = "<div id='year_#{year}'>#{year}|"
    while year <= to_year
      if year == to_year
        while month <= to_month
          out += link_to_unless(selected_year == year && selected_month == month, month.to_s, :action => current_action, :year=>year, :month=>month) + "|"
          month += 1
        end
        out += "</div>"
        break;
      else
        while month < 13
          out += link_to_unless(selected_year == year && selected_month == month, month.to_s, :action => current_action, :year=>year, :month=>month) + "|"
          month += 1
        end
        month = 1
        year += 1
        out += "</div><div id='year_#{year}'>#{year}|"
      end  

    end
    return out.html_safe
  end
end
