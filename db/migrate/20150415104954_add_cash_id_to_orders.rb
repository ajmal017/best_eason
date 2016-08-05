class AddCashIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :cash_id, :integer
  end
end
