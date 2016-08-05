class CreateOrderErrs < ActiveRecord::Migration
  def change
    create_table :order_errs do |t|
      t.integer :order_id
      t.integer :ib_order_id
      t.string :symbol
      t.string :code
      t.string :message

      t.timestamps null: false
    end
  end
end
