class AddTypeToTradingAccounts < ActiveRecord::Migration
  def change
    add_column :trading_accounts, :type, :string
  end
end
