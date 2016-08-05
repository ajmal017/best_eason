class AddOrderNumToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :order_num, :string
  end
end