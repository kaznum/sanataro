class ChangeSessionDataToText < ActiveRecord::Migration
  def up
    change_column :sessions, :data, :text
  end

  def down
    execute "ALTER TABLE sessions CHANGE COLUMN data data LONGTEXT"
  end
end
