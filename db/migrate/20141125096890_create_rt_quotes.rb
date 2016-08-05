class CreateRtQuotes < ActiveRecord::Migration
  def change
    create_table :rt_quotes, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
      t.integer :base_stock_id
      t.string :symbol, limit: 30
      t.string :market, limit: 10

      t.decimal :previous_close, precision: 10, scale: 3
      t.decimal :last, precision: 10, scale: 3
      t.decimal :high52_weeks, precision: 10, scale: 3
      t.decimal :low52_weeks, precision: 10, scale: 3
      t.decimal :open, precision: 10, scale: 3
      t.decimal :high, precision: 10, scale: 3
      t.decimal :low, precision: 10, scale: 3
      t.decimal :ask, precision: 10, scale: 3
      t.decimal :bid, precision: 10, scale: 3

      t.string :change_from_previous_close, limit: 10
      t.string :percent_change_from_previous_close, limit: 10
      t.string :currency, limit: 10
      t.integer :volume
      
      t.datetime :trade_time
      t.datetime :expired_at

      t.timestamps
    end

    add_index :rt_quotes, [:base_stock_id, :trade_time], unique: true
    add_index :rt_quotes, :trade_time
    add_index :rt_quotes, :expired_at
    add_index :rt_quotes, :symbol
  end
end
