class AddTradingDateToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :trading_date, :date
    add_column :brokers, :trading_date_synced_at, :datetime
  end
end
