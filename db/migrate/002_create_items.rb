class CreateItems < ActiveRecord::Migration
  def self.up
        create_table(:items, {}) {|table|
                table.column :user_id,	:string
                table.column :name,	:string
		table.column :type_id,	:integer
		table.column :from_account_id,	:integer
		table.column :to_account_id,	:integer
		table.column :currency,	:string
		table.column :amount,	:string
		table.column :action_date,	:date
		table.column :regist_datetime,  :datetime
        }
  end

  def self.down
    drop_table :items
  end
end
