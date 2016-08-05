class CreateRetryOrders < ActiveRecord::Migration
  def change
    create_table :retry_orders do |t|
      t.integer :order_id

      t.timestamps
    end
  end
end
