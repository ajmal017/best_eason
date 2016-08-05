class AddTradingAccountIdToAccountValues < ActiveRecord::Migration
  def change
    add_column :account_values, :trading_account_id, :integer

    add_index :account_values, :trading_account_id
  end
end
