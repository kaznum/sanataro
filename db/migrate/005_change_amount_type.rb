class ChangeAmountType < ActiveRecord::Migration
  def self.up
	change_column :items, :amount, :integer
  end

  def self.down
  end
end
