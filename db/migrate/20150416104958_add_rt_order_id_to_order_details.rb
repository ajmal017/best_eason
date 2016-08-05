class AddRtOrderIdToOrderDetails < ActiveRecord::Migration
  def change
    add_column :order_details, :rt_order_id, :string

    add_index :order_details, :rt_order_id
  end
end
