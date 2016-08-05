class ChangeIbPositionTradingAccountId < ActiveRecord::Migration
  def change
    change_column :ib_positions, :trading_account_id, :integer
  end
end
