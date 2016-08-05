class CreateUserStockProfits < ActiveRecord::Migration
  def change
    create_table :user_stock_profits do |t|
      t.integer :user_id
      t.integer :trading_account_id
      t.integer :stock_id
      t.date :date
      t.float :total_pnl
      t.float :today_pnl
      t.float :total_buyed

      t.timestamps
    end

    add_index :user_stock_profits, [:user_id, :trading_account_id, :stock_id], unique: true, name: "idx_of_user_stock_profits"
  end
end