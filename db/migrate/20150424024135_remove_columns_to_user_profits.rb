class RemoveColumnsToUserProfits < ActiveRecord::Migration
  def change
    remove_column :user_profits, :hk_pnl
    remove_column :user_profits, :us_pnl
    remove_column :user_profits, :finished

    remove_index :user_profits, [:user_id, :date]
    add_index :user_profits, [:trading_account_id, :date], unique: true
  end
end
