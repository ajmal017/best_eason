class AddIndexToOrderDetails < ActiveRecord::Migration
  def change
    add_index :order_details, [:user_id, :trading_account_id, :trade_time], name: 'combine_indexes_for_order_details'
  end
end
