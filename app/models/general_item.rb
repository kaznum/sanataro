class GeneralItem < Item
  def fill_amount
    # do nothing
  end

  def update_with_filter!(args)
    filter_and_assign_attributes args
    save!
    reload
    self
  end

  def filter_and_assign_attributes(attrs)
    if persisted? && parent_item
      new_attrs = attrs.select { |key, value| key.to_sym == :action_date }
    else
      new_attrs = attrs.select {|key, value|
        [:name, :from_account_id, :to_account_id, :confirmation_required, :tag_list, :action_date, :amount].include?(key.to_sym)
      }
    end
    assign_attributes(new_attrs)
    new_attrs
  end
end

