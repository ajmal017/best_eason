class CreateIndexToTradingAccounts < ActiveRecord::Migration
  def change
    add_index :trading_accounts, :status
  end
end
