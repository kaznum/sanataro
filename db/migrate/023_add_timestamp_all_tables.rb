class AddTimestampAllTables < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :regist_datetime, :created_at
    add_column :accounts, :updated_at, :timestamp
    rename_column :autologin_keys, :regist_datetime, :created_at
    add_column :autologin_keys, :updated_at, :timestamp
    add_column :credit_relations, :created_at, :timestamp
    add_column :credit_relations, :updated_at, :timestamp
    rename_column :items, :regist_datetime, :created_at
    add_column :items, :updated_at, :timestamp
    add_column :monthly_profit_losses, :created_at, :timestamp
    add_column :monthly_profit_losses, :updated_at, :timestamp
    rename_column :users, :regist_datetime, :created_at
    add_column :users, :updated_at, :timestamp
  end

  def self.down
    rename_column :accounts, :created_at, :regist_datetime
    remove_column :accounts, :updated_at
    rename_column :autologin_keys, :created_at, :regist_datetime
    remove_column :autologin_keys, :updated_at
    remove_column :credit_relations, :created_at
    remove_column :credit_relations, :updated_at
    rename_column :items, :created_at, :regist_datetime
    remove_column :items, :updated_at
    remove_column :monthly_profit_losses, :created_at
    remove_column :monthly_profit_losses, :updated_at
    rename_column :users, :created_at, :regist_datetime
    remove_column :users, :updated_at
  end
end
