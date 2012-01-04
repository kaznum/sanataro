class CreateUsers < ActiveRecord::Migration
  def self.up
	create_table(:users, {}) {|table|
		table.column :login,	:string
		table.column :password,	:string
		table.column :regist_datetime,	:datetime
		table.column :is_active,	:boolean, :default=>true
	}

	User.create(:login=>"numata", :password=>'BYB4xEX6lMpTs') #123456
  end

  def self.down
	drop_table :users
  end

end

