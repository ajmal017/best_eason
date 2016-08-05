class CreateBaseStocks < ActiveRecord::Migration
  def change
    create_table :base_stocks do |t|
      t.string :name
      t.string :c_name
      t.string :symbol
      t.string :abbrev
      t.string :exchange
      t.string :ib_symbol
      t.integer :board_lot, :integer, default: 1
      t.string :data_source
      t.boolean :qualified, default: false
      t.integer :ib_id
      t.date :date
      t.string :img
      t.string :stock_type
      t.string :ticker
      t.decimal :last_price, precision: 16, scale: 2
      t.integer :follows_count, default: 0
      
      t.timestamps
    end
    
    add_index :base_stocks, :ticker
    add_index :base_stocks, :date
    add_index :base_stocks, :ib_id
    add_index :base_stocks, :ib_symbol
    add_index :base_stocks, :symbol
  end
end
