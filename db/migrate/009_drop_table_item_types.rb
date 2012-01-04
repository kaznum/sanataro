class DropTableItemTypes < ActiveRecord::Migration
  def self.up
	drop_table :item_types
  end

  def self.down
  end
end
