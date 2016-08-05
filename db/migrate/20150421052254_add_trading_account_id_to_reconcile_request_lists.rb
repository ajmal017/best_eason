class AddTradingAccountIdToReconcileRequestLists < ActiveRecord::Migration
  def change
    add_column :reconcile_request_lists, :trading_account_id, :string
    add_column :reconcile_request_lists, :type, :string
  end
end
