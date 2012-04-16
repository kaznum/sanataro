class AddColumnUserIdToItemTypes < ActiveRecord::Migration
  def self.up
    add_column :item_types, :order_no, :integer
    add_column :item_types, :user_id, :integer
  end

  def self.down
    remove_column :item_types, :user_id
    remove_column :item_types, :order_no
  end
end
