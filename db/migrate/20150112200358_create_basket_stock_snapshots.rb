class CreateBasketStockSnapshots < ActiveRecord::Migration
  def self.up
    create_table :basket_stock_snapshots do |t|
      t.integer :basket_id
      t.integer :stock_id
      t.integer :basket_adjustment_id
      t.decimal :weight, :precision => 6, :scale => 4
      t.float :stock_price
      t.timestamps
    end

    add_index :basket_stock_snapshots, [:basket_id, :stock_id, :basket_adjustment_id], unique: true, name: "index_bss_on_basket_and_stock_and_adjustment_id"
  end

  def self.down
    drop_table :basket_stock_snapshots
  end
end