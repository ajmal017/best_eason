class ChangeIbPositionIndex < ActiveRecord::Migration
  def up
    remove_index :ib_positions, [:user_id, :base_stock_id]
    add_index :ib_positions, [:trading_account_id, :base_stock_id]
  end

  def down
    add_index :ib_positions, [:user_id, :base_stock_id]
    remove_index :ib_positions, [:trading_account_id, :base_stock_id]
  end
end
