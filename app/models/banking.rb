# frozen_string_literal: true

class Banking < Account
  def status_of_the_day(date)
    self.class.asset(user, id, date)
  end
end
