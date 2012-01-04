class ChangeTypeItemsUserId < ActiveRecord::Migration
  def self.up
	change_column :items, :user_id, :integer, :null=>false
  end

  def self.down
	change_column :items, :user_id, :string
  end
end
