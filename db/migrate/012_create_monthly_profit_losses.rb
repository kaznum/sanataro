class CreateMonthlyProfitLosses < ActiveRecord::Migration
  def self.up
    create_table :monthly_profit_losses do |t|
	t.column :user_id, :integer
	t.column :month, :date
	t.column :from_account_id, :integer
    end
  end

  def self.down
    drop_table :monthly_profit_losses
  end
end
