class CreateBasketStocks < ActiveRecord::Migration
  def change
    create_table :basket_stocks do |t|
      t.integer :stock_id
      t.integer :basket_id
      t.decimal :weight, :precision => 10, :scale => 4
      t.text :notes, :limit => 320
      t.decimal :adjusted_weight, :precision => 20, :scale => 18
        
      t.timestamps
    end
    
    add_index :basket_stocks, :stock_id
    add_index :basket_stocks, :basket_id
  end
end
