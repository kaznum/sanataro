class Expense < Account
  def status_of_the_day(date)
    self.class.asset_beginning_of_month_to_date(user, id, date)
  end
end
