class AddChildParentIdItems < ActiveRecord::Migration
  def self.up
	add_column :items, :parent_id, :integer
	add_column :items, :child_id, :integer
  end

  def self.down
  end
end
