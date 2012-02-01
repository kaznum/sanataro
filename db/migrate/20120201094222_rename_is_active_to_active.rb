class RenameIsActiveToActive < ActiveRecord::Migration
  def change
    rename_column :accounts, :is_active, :active
    rename_column :users, :is_active, :active
  end
end
