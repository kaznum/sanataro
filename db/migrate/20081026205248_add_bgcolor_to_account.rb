class AddBgcolorToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :bgcolor, :string
  end

  def self.down
    remove_column :accounts, :bgcolor
  end
end
