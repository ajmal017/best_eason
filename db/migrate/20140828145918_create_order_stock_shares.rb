class CreateOrderStockShares < ActiveRecord::Migration
  def self.up
    # 每次创建order时，把每个basket对应的股票数量记录下来
    create_table :order_stock_shares do |t|
      t.string :instance_id
      t.integer :order_id
      t.integer :base_stock_id
      t.integer :shares

      t.timestamps
    end
    
    add_index :order_stock_shares, :order_id
    add_index :order_stock_shares, :instance_id
    add_index :order_stock_shares, :base_stock_id
  end

  def self.down
    drop_table :order_stock_shares
  end
end