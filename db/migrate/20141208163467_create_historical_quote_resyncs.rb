class CreateHistoricalQuoteResyncs < ActiveRecord::Migration
  def change
    create_table :historical_quote_resyncs do |t|
      t.string :symbol
      t.integer :base_stock_id
      t.decimal :old_last, precision: 16, scale: 3
      t.decimal :new_last, precision: 16, scale: 3
      t.boolean :kline, default: false

      t.timestamps
    end

    add_index :historical_quote_resyncs, [:base_stock_id, :kline]
  end
end
