class CreateOrderDetails < ActiveRecord::Migration
  def change
    create_table :order_details do |t|
      t.integer :order_id
      
      # 仓位
      t.string :instance_id, limit: 50
      
      t.integer :base_stock_id
      t.integer :user_id
      t.integer :basket_id

      # 预计购买数量
      t.decimal :est_shares, precision: 16, scale: 2

      # 实际购买数量
      t.decimal :real_shares, precision: 16, scale: 2

      # 预计花费
      t.decimal :est_cost, precision: 16, scale: 3

      # 实际花费
      t.decimal :real_cost, precision: 16, scale: 3
      
      # 限價
      t.decimal :limit_price, precision: 16, scale: 2
      
      # 状态
      t.string :status
      
      t.string :order_type
      t.string :trade_type
      t.datetime :trade_time
      
      t.string :symbol

      # IB order id
      t.integer :ib_order_id
      
      t.string :updated_by

      t.timestamps
    end

    add_index :order_details, :order_id
    add_index :order_details, :instance_id
    add_index :order_details, :base_stock_id
    add_index :order_details, :user_id
    add_index :order_details, :basket_id
    add_index :order_details, :status
    add_index :order_details, :symbol
    add_index :order_details, :ib_order_id
    
    add_index :order_details, [:instance_id, :symbol]
    add_index :order_details, [:instance_id, :base_stock_id]
  end
end
