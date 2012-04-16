class ChangeColumnAccountIdPl < ActiveRecord::Migration
  def self.up
    rename_column :monthly_profit_losses, :from_account_id, :account_id
  end

  def self.down
    rename_column :monthly_profit_losses, :account_id, :from_account_id
  end
end
