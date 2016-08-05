class CreatePositions < ActiveRecord::Migration
  def change
    create_table :positions do |t|
      t.string :instance_id, limit: 50
      t.integer :base_stock_id
      t.integer :basket_id
      t.integer :user_id
      
      # Base Stock 份数
      t.decimal :shares, precision: 16, scale: 2
      
      # 主题 份数
      t.decimal :basket_mount, precision: 16, scale: 2
      
      t.decimal :average_cost, precision: 16, scale: 10, default: 0.0
      
      t.string :updated_by
      t.integer :pending_shares, default: 0
      
      t.timestamps
    end

    add_index :positions, :instance_id
    add_index :positions, :base_stock_id
    add_index :positions, :basket_id
    add_index :positions, :user_id
    
    add_index :positions, [:instance_id, :base_stock_id, :user_id], :unique => true
  end
end
