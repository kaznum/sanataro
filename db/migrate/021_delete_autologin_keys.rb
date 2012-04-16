class DeleteAutologinKeys < ActiveRecord::Migration
  def self.up
    remove_column :users, :autologin_key
  end

  def self.down
    add_column :users, :autologin_key, :string
  end
end
