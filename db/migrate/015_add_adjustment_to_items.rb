class AddAdjustmentToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :is_adjustment, :boolean, :default=>false
    add_column :items, :adjustment_amount, :integer, :default=>0
  end

  def self.down
    remove_column :items, :is_adjustment
    remove_column :items, :adjustment_amount
  end
end
