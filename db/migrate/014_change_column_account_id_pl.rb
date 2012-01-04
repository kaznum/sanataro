class ChangeColumnAccountIdPl < ActiveRecord::Migration
  def self.up
	rename_column :monthly_profit_losses, :from_account_id, :account_id
  end

  def self.down
  end
end
