class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      # 仓位
      t.string :instance_id, limit: 50
      
      t.integer :user_id
      t.integer :basket_id
      # motif份数
      t.decimal :basket_mount, precision: 16, scale: 2
      
      # 预计花费
      t.decimal :est_cost, precision: 16, scale: 2

      # 实际花费
      t.decimal :real_cost, precision: 16, scale: 2

      # 买入 卖出
      t.string :type
      
      t.string :status
      
      t.datetime :expiry
      
      t.boolean :background
      
      t.integer :order_details_complete_count, default: 0
      
      t.string :updated_by

      t.timestamps
    end

    add_index :orders, :instance_id
    add_index :orders, :user_id
    add_index :orders, :basket_id
    add_index :orders, :basket_mount
  end
end
