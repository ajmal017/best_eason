class AddCommissionToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :commission, :decimal, precision: 16, scale: 2, default: 0.0
    add_column :order_details, :commission, :decimal, precision: 16, scale: 2, default: 0.0
  end
end
