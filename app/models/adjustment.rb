class Adjustment < Item
  # before_create :destroy_previous_adjustment_of_the_day

  def fill_amount
    if !amount_changed? || new_record? # && action_date && to_account_id && user && adjustment_amount
      asset = user.accounts.asset(user, to_account_id, action_date, id)
      self.amount = adjustment_amount - asset
    end
  end
end
