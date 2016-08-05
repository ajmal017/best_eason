class AddRtOrderIdUniqIndexToOrderDetails < ActiveRecord::Migration
  def change
    remove_index :order_details, :rt_order_id if index_exists? :order_details, :rt_order_id
    add_index :order_details, :rt_order_id, unique: true
  end
end
