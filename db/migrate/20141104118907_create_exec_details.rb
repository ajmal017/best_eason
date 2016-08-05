class CreateExecDetails < ActiveRecord::Migration
  def change
    create_table :exec_details do |t|
      t.string :basket_id
      t.integer :order_id
      t.string :instance_id
      t.string :exchange
      t.string :currency
      t.string :symbol
      t.integer :contract_id
      t.string :account_name
      t.decimal :avg_price, precision: 16, scale: 10
      t.integer :cum_quantity
      t.string :exec_exchange
      t.string :exec_id
      t.integer :ib_order_id
      t.integer :perm_id
      t.decimal :price, precision: 16, scale: 10
      t.integer :shares
      t.string :side
      t.string :time
      t.string :ev_rule
      t.decimal :ex_multiplier, precision: 16, scale: 10
      t.boolean :processed
      
      t.timestamps
    end
    
    add_index :exec_details, :contract_id
    add_index :exec_details, :exec_id
    add_index :exec_details, :ib_order_id
    add_index :exec_details, [:ib_order_id, :time]
  end
end
