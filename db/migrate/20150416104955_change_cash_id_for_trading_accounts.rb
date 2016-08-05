class ChangeCashIdForTradingAccounts < ActiveRecord::Migration
  def change
    remove_index :trading_accounts, :cash_id if index_exists?(:trading_accounts, :cash_id)
    change_column :trading_accounts, :cash_id, :string
    add_index :trading_accounts, :cash_id
    
    change_column :orders, :cash_id, :string
  end
end
