class CreateIbPositions < ActiveRecord::Migration
  def change
    create_table :ib_positions do |t|
      t.integer :user_id
      t.integer :base_stock_id
      t.string :symbol
      t.integer :contract_id
      t.string :account_name
      t.decimal :position, precision: 16, scale: 2
      t.string :exchange

      t.timestamps null: false
    end

    add_index :ib_positions, [:user_id, :base_stock_id]
  end
end
