class AddCashIdToTradingAccounts < ActiveRecord::Migration

  def change
    add_column :trading_accounts, :cash_id, :integer

    add_index :trading_accounts, :cash_id
    add_index :trading_accounts, :user_id
    add_index :trading_accounts, :broker_no, length: 15
  end
end
