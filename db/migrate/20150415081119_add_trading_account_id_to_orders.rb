class AddTradingAccountIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :trading_account_id, :integer

    add_index :orders, :trading_account_id
  end
end