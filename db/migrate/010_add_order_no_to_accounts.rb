class AddOrderNoToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :order_no, :integer
  end

  def self.down
    remove_column :accounts, :order_no
  end
end
