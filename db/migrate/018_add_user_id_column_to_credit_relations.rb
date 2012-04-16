class AddUserIdColumnToCreditRelations < ActiveRecord::Migration
  def self.up
    add_column :credit_relations, :user_id, :integer
  end

  def self.down
    remove_column :credit_relations, :user_id
  end
end
