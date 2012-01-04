class AddEmailAndConfirmationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string
    add_column :users, :confirmation, :string
  end

  def self.down
    remove_column :users, :confirmation
    remove_column :users, :email
  end
end
