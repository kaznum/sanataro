class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users, {}) {|table|
      table.column :login, :string
      table.column :password, :string
      table.column :regist_datetime, :datetime
      table.column :is_active, :boolean, :default=>true
    }
  end

  def self.down
    drop_table :users
  end
end

