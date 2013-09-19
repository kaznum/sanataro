class Adjustment < Item
  before_create :remove_previous_adjustment_of_same_action_date

  validates :action_date, uniqueness: { scope: [:action_date, :to_account_id, :type] }, on: :update

  def fill_amount
    if !amount_changed? || new_record?
      raise InvalidDate unless action_date

      asset = user.accounts.asset(user, to_account_id, action_date, id)
      self.amount = adjustment_amount - asset
    end
  end

  def update_with_filter!(args)
    # For simple adjustment, set amount = 0 at once
    # This is to set correct amounts of other adjustment items to calcurate "amount" later.
    # The following is only for JRuby + SQLite3
    # Primarily, this code isn't required, but the result of update_attributes!(amount:0)
    # got stored unfortunately when an exception happens after the code, so in advance,
    # check the validation of the parameters.
    # This problem has been seen the following environment.
    # JRuby 1.6.7, head(2012-4-6)
    # activerecord-jdbcsqlite3-adapter (1.2.2)
    # activerecord-jdbc-adapter (1.2.2)
    # jdbc-sqlite3 (3.7.2)
    filter_and_assign_attributes(args)
    valid? || (raise ActiveRecord::RecordInvalid.new(self))
    reload
    # The End of code Only for JRuby + SQLite3
    update_attributes!(amount: 0)
    reload
    filter_and_assign_attributes(args)
    save!
    reload
    self
  end

  def filter_and_assign_attributes(attrs)
    if persisted?
      adjusted_attrs = attrs.select { |key, value| [:to_account_id, :action_date, :adjustment_amount, :tag_list].include?(key.to_sym) }
    else
      adjusted_attrs = attrs.select { |key, value| [:to_account_id, :confirmation_required, :tag_list, :action_date, :adjustment_amount].include?(key.to_sym) }
      adjusted_attrs[:name] = 'Adjustment'
      adjusted_attrs[:from_account_id] = -1
    end

    assign_attributes(adjusted_attrs)
    adjusted_attrs
  end

  private

  def remove_previous_adjustment_of_same_action_date
    prev_adj = user.adjustments.find_by_to_account_id_and_action_date(to_account_id, action_date)
    prev_adj.destroy if prev_adj
    fill_amount
  end
end
