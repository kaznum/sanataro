class RenameAccountsTypeColumn < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :type, :account_type
  end

  def self.down
    rename_column :accounts, :account_type, :type
  end
end
