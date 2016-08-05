class ChangeOrderNumToSnOfOrders < ActiveRecord::Migration
  def change
    rename_column :orders, :order_num, :sn
  end
end