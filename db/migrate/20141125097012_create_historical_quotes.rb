class CreateHistoricalQuotes < ActiveRecord::Migration
  def change
    create_table :historical_quotes, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
      t.integer :base_stock_id
      t.string :symbol

      t.decimal :last, precision: 10, scale: 3
      t.decimal :open, precision: 10, scale: 3
      t.decimal :high, precision: 10, scale: 3
      t.decimal :low, precision: 10, scale: 3
      t.decimal :last_close, precision: 10, scale: 3
      t.decimal :change_from_open, precision: 9, scale: 3
      t.decimal :percent_change_from_open, precision: 9, scale: 3
      t.decimal :change_from_last_close, precision: 9, scale: 3
      t.decimal :percent_change_from_last_close, precision: 9, scale: 3
      t.decimal :index, precision: 30, scale: 13

      t.integer :volume

      t.date :date

      t.timestamps
    end

    add_index :historical_quotes, [:base_stock_id, :date], unique: :true
    add_index :historical_quotes, :symbol
    add_index :historical_quotes, :date
  end
end
