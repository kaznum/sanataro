class RenameIsAdjustmentToAdjustment < ActiveRecord::Migration
  def change
    rename_column :items, :is_adjustment, :adjustment
  end
end
