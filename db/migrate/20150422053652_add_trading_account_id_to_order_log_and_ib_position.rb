class AddTradingAccountIdToOrderLogAndIbPosition < ActiveRecord::Migration
  def change
    add_column :ib_positions, :trading_account_id, :string
    add_column :order_logs, :trading_account_id, :string
  end
end
