class AddConfirmationRequiredToItems < ActiveRecord::Migration
  def self.up
	add_column :items, :confirmation_required, :boolean, :default => false
  end

  def self.down
	remove_column :items, :confirmation_required
  end
end
