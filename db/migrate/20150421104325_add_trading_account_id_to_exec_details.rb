class AddTradingAccountIdToExecDetails < ActiveRecord::Migration
  def change
    add_column :exec_details, :trading_account_id, :integer
    add_index :exec_details, :trading_account_id
  end
end
