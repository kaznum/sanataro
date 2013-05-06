class RenameAccountTypeToTypeInAccounts < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :account_type, :type
    Account.where(type: 'income').update_all(type: "Income")
    Account.where(type: 'outgo').update_all(type: "Expense")
    Account.where(type: 'account').update_all(type: "Banking")
  end

  def self.down
    rename_column :accounts, :type, :account_type
    Account.where(account_type: "Income").update_all(account_type: 'income')
    Account.where(account_type: "Expense").update_all(account_type: 'outgo')
    Account.where(account_type: "Banking").update_all(account_type: 'account')
  end
end
