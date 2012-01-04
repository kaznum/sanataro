class ChangeSessionDataType < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE sessions CHANGE COLUMN data data LONGTEXT"
  end

  def self.down
    execute "ALTER TABLE sessions CHANGE COLUMN data data TEXT"
  end
end
