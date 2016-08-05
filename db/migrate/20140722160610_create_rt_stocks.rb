class CreateRtStocks < ActiveRecord::Migration
  def change
    create_table :rt_stocks do |t|
      t.integer :base_id
      t.string :symbol
      t.integer :average_daily_volume, limit: 8
      t.decimal :ask_realtime, precision: 16, scale: 3
      t.decimal :bid_realtime, precision: 16, scale: 3
      t.string  :change
      t.decimal :dividend_share, precision: 16, scale: 3
      t.decimal :earnings_share, precision: 16, scale: 3
      t.decimal :days_low, precision: 16, scale: 3
      t.decimal :days_high, precision: 16, scale: 3
      t.decimal :year_low, precision: 16, scale: 3
      t.decimal :year_high, precision: 16, scale: 3
      t.decimal :market_capitalization, precision: 30, scale: 3
      t.decimal :last_trade_price_only, precision: 16, scale: 3
      t.string :days_range
      t.string :name
      t.decimal :open, precision: 16, scale: 3
      t.decimal :previous_close, precision: 16, scale: 3
      t.string :changein_percent
      t.decimal :pe_ratio, precision: 16, scale: 3
      t.string :last_trade_time
      t.integer :volume, limit: 8
      t.string :year_range
      t.string :stock_exchange
      t.decimal :high, precision: 16, scale: 3
      t.decimal :low, precision: 16, scale: 3
      t.string :status, default: 'Trading'
      t.string :currency
      t.date :date
      t.string :market_capitalization

      t.timestamps

    end
    
    add_index :rt_stocks, [:base_id, :date], unique: true
  end
end
