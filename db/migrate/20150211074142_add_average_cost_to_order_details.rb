class AddAverageCostToOrderDetails < ActiveRecord::Migration
  def change
    add_column  :order_details, :average_cost, :decimal, precision: 16, scale: 10, default: 0.0
  end
end
