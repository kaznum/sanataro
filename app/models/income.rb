# frozen_string_literal: true

class Income < Account
  def status_of_the_day(date)
    (-1) * self.class.asset_beginning_of_month_to_date(user, id, date)
  end
end
