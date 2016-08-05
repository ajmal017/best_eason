class AddTradingAccountIdToUserProfits < ActiveRecord::Migration
  
  def change
    add_column :user_profits, :trading_account_id, :integer
    add_index :user_profits, :trading_account_id
  end
end
