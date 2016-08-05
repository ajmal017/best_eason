class CreateBasketAdjustLogs < ActiveRecord::Migration
  def self.up
    create_table :basket_adjust_logs do |t|
      t.integer :basket_adjustment_id
      t.integer :stock_id
      t.integer :action
      t.decimal :weight_from, :precision => 6, :scale => 4
      t.decimal :weight_to, :precision => 6, :scale => 4
      t.float :stock_price
      t.timestamps
    end

    add_index :basket_adjust_logs, [:basket_adjustment_id, :stock_id], unique: true
  end

  def self.down
    drop_table :basket_adjust_logs
  end
end