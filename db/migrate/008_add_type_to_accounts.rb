class AddTypeToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :type, :string
  end

  def self.down
    remove_column :accounts, :type
  end
end
