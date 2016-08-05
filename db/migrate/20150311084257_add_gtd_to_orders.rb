class AddGtdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :gtd, :boolean
  end
end
