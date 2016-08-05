class CreateIbFundamentals < ActiveRecord::Migration
  def change
    create_table :ib_fundamentals do |t|
      t.string :exchange, null: false
      t.string :symbol, null: false
      t.text :current_xml
      t.text :forecast_xml
      t.string :country_code
      t.decimal :target_price, precision: 16, scale: 2, default: 0
      t.decimal :pe, precision: 16, scale: 4, default: 0
      t.decimal :peer_pe, precision: 16, scale: 4, default: 0
      t.decimal :growth, precision: 16, scale: 4, default: 0
      t.decimal :peer_growth, precision: 16, scale: 4, default: 0
      t.decimal :forecast_growth, precision: 16, scale: 4, default: 0
      t.decimal :net_profit, precision: 16, scale: 0, default: 0
      t.decimal :forecast_profit, precision: 16, scale: 0, default: 0
      t.decimal :revenue, precision: 16, scale: 0, default: 0
      t.decimal :forecast_revenue, precision: 16, scale: 0, default: 0
      t.decimal :dividend, precision: 16, scale: 2, default: 0
      t.decimal :dividend_yield, precision: 16, scale: 4, default: 0
      t.decimal :quick_ratio, precision: 16, scale: 4, default: 0
      t.decimal :price_to_book, precision: 16, scale: 4, default: 0
      t.decimal :price_to_sales, precision: 16, scale: 4, default: 0
      t.decimal :price_to_cashflow, precision: 16, scale: 4, default: 0
      t.decimal :ebitd_to_marketcap, precision: 16, scale: 4, default: 0
      t.decimal :profit_margin, precision: 16, scale: 4, default: 0

      t.timestamps
    end
    
    add_index :ib_fundamentals, :exchange
    add_index :ib_fundamentals, :symbol
    add_index :ib_fundamentals, [:symbol, :exchange], unique: true
  end
end
