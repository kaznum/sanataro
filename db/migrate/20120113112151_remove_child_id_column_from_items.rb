class RemoveChildIdColumnFromItems < ActiveRecord::Migration
  def up
    remove_column :items, :child_id
  end

  def down
    add_column :items, :child_id, :integer
  end
end
