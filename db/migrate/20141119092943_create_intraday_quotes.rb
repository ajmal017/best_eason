class CreateIntradayQuotes < ActiveRecord::Migration
  def change
    create_table :intraday_quotes, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
      t.integer :base_id
      t.string :symbol, limit: 30
      t.string :market, limit: 10
      t.datetime :trade_time
      t.integer :volume
      t.decimal :last_trade_price_only, precision: 8, scale: 3
      t.string :changein_percent
      t.decimal :change, precision: 8, scale: 3
      t.decimal :previous_close, precision: 8, scale: 3
      t.datetime :expired_at
      t.datetime :created_at
    end
    add_index :intraday_quotes, [:base_id, :trade_time],  unique: true
    add_index :intraday_quotes, :trade_time
    add_index :intraday_quotes, :expired_at
  end
end
