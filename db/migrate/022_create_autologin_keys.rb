class CreateAutologinKeys < ActiveRecord::Migration
  def self.up
    create_table :autologin_keys do |t|
	t.column :user_id,	:integer
	t.column :enc_autologin_key,	:string
	t.column :regist_datetime, :datetime
    end
  end

  def self.down
    drop_table :autologin_keys
  end
end
