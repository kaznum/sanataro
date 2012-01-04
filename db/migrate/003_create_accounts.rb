class CreateAccounts < ActiveRecord::Migration
  def self.up
        create_table(:accounts, {}) {|table|
                table.column :user_id,		:integer
		table.column :name,	:string
                table.column :regist_datetime,  :datetime
                table.column :is_active,        :boolean, :default=>true
        }

  end

  def self.down
    drop_table :accounts
  end
end
