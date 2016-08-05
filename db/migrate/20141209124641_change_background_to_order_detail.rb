class ChangeBackgroundToOrderDetail < ActiveRecord::Migration
  def change
    change_column :order_details, :background, :boolean, default: false
  end
end
