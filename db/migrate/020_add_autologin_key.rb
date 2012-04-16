class AddAutologinKey < ActiveRecord::Migration
  def self.up
    add_column :users, :autologin_key, :string
  end

  def self.down
    remove_column :users, :autologin_key
  end
end
