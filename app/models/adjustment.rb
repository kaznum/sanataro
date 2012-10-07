class Adjustment < Item
  private

  def fill_amount
    if !amount_changed? && action_date && to_account_id && user && adjustment_amount
      asset = user.accounts.asset(user, to_account_id, action_date, id)
      self.amount = adjustment_amount - asset
    end
  end
end

