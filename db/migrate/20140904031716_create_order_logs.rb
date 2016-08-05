class CreateOrderLogs < ActiveRecord::Migration
  def change
    create_table :order_logs do |t|
      t.integer :user_id
      t.integer :order_id
      t.integer :ib_order_id
      t.string :instance_id
      t.integer :base_stock_id
      t.integer :sequence
      t.integer :filled
      t.decimal :cost, precision: 16, scale: 3, default: 0
      t.integer :remaining
      t.integer :total_filled
      t.decimal :avg_price, precision: 16, scale: 2, default: 0

      t.timestamps
    end

    add_index :order_logs, :user_id
    add_index :order_logs, :ib_order_id
    add_index :order_logs, :instance_id
    add_index :order_logs, [:ib_order_id, :base_stock_id]
  end
end
