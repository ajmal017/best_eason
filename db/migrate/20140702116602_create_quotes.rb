class CreateQuotes < ActiveRecord::Migration
  def change
    create_table :quotes do |t|
      t.string :symbol, null: false
      t.date :date
      t.decimal :open, precision: 16, scale: 3
      t.decimal :high, precision: 16, scale: 3
      t.decimal :low, precision: 16, scale: 3
      t.decimal :close, precision: 16, scale: 3
      t.integer :volume, limit: 8
      t.decimal :adj_close, precision: 16, scale: 3
      t.decimal :index, precision: 30, scale: 13
      t.integer :base_id
      
      
      t.timestamps
    end
    
    add_index :quotes, :base_id
    add_index :quotes, :date
    add_index :quotes, [:base_id, :date], :unique => true
  end
end
