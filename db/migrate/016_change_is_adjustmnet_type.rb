class ChangeIsAdjustmnetType < ActiveRecord::Migration
  def self.up
	change_column :items, :is_adjustment, :boolean, :default=>false
  end

  def self.down
  end
end
