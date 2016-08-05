class AddTradingAccountIdToExchangeRate < ActiveRecord::Migration
  def change
    add_column :exchange_rates, :trading_account_id, :integer
    add_index :exchange_rates, [:trading_account_id, :currency]
  end
end
