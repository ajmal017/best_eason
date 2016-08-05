class AddBackgroundToOrderDetail < ActiveRecord::Migration
  def change
    add_column :order_details, :background, :boolean
  end
end
