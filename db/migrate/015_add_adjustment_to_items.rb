class AddAdjustmentToItems < ActiveRecord::Migration
  def self.up
	add_column :items, :is_adjustment, :integer, :default=>false
	add_column :items, :adjustment_amount, :integer, :default=>0
  end

  def self.down
  end
end
