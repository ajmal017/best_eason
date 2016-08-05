class ChangePositionIndex < ActiveRecord::Migration
  def up
    remove_index :positions, [:instance_id, :base_stock_id, :user_id]
    add_index :positions, [:instance_id, :base_stock_id, :trading_account_id], :unique => true, name: 'instance_stock_account_unique_index'
  end

  def down
    add_index :positions, [:instance_id, :base_stock_id, :user_id], unique: true
    remove_index :positions, name: 'instance_stock_account_unique_index'
  end
end
