class AddAmountToMonthlyprofitloss < ActiveRecord::Migration
  def self.up
	add_column :monthly_profit_losses, :amount, :integer
  end

  def self.down
  end
end
