class AddNextBasketIdToBasketStockSnapshots < ActiveRecord::Migration
  def change
    add_column :basket_stock_snapshots, :next_basket_id, :integer
    add_column :basket_stock_snapshots, :notes, :text, :limit => 320
    add_column :basket_stock_snapshots, :adjusted_weight, :decimal, :precision => 20, :scale => 18
    add_column :basket_stock_snapshots, :ori_weight, :decimal, precision: 6, scale: 4

    add_index :basket_stock_snapshots, [:basket_id, :next_basket_id]
  end
end