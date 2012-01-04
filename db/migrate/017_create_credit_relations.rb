class CreateCreditRelations < ActiveRecord::Migration
  def self.up
    create_table :credit_relations do |t|
	t.column :credit_account_id, :integer
	t.column :payment_account_id, :integer
	t.column :settlement_day, :integer
	t.column :payment_month, :integer
	t.column :payment_day, :integer
    end
  end

  def self.down
    drop_table :credit_relations
  end
end
