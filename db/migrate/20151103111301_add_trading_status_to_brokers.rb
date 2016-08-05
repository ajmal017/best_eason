class AddTradingStatusToBrokers < ActiveRecord::Migration
  def up
    add_column :brokers, :trading_status, :integer, default: 0
    Broker.update_all(trading_status: 0)
  end

  def down
    remove_column :brokers, :trading_status
  end
end
