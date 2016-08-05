class ChangeIbOrderIdType < ActiveRecord::Migration
  def change
    change_column :exec_details, :ib_order_id, :string
    change_column :order_logs, :ib_order_id, :string
    change_column :order_details, :ib_order_id, :string
  end
end
