class AddResultToOrderDetails < ActiveRecord::Migration
  def change
    add_column :order_details, :result, :string, limit: 100
  end
end
