class AddRtOrderIdToExecDetails < ActiveRecord::Migration
  def change
    add_column :exec_details, :rt_order_id, :string
  end
end
