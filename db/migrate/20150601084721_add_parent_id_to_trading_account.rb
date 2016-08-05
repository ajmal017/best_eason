class AddParentIdToTradingAccount < ActiveRecord::Migration
  def change
    add_column :trading_accounts, :parent_id, :integer
  end
end
