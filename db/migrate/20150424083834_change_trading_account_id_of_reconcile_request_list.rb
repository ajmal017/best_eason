class ChangeTradingAccountIdOfReconcileRequestList < ActiveRecord::Migration
  def change
    change_column :reconcile_request_lists, :trading_account_id, :integer
  end
end
