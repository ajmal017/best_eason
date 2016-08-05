class CreateStockChanges < ActiveRecord::Migration
  def change
    create_table :stock_changes do |t|
      t.integer :from_id
      t.integer :to_id
      t.string :from_symbol
      t.string :to_symbol
      t.date :date
      t.string :factor

      t.timestamps null: false
    end
  end
end
