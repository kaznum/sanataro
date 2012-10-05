class RenameAccountTypeToTypeInAccounts < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :account_type, :type
    Account.update_all({type: "Income"}, {type: 'income'})
    Account.update_all({type: "Expense"}, {type: 'outgo'})
    Account.update_all({type: "Banking"}, {type: 'account'})
  end

  def self.down
    rename_column :accounts, :type, :account_type
    Account.update_all({account_type: 'income'}, {account_type: "Income"})
    Account.update_all({account_type: 'outgo'}, {account_type: "Expense"})
    Account.update_all({account_type: 'account'}, {account_type: "Banking"})
   end
end
