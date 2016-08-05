class CreateKlines < ActiveRecord::Migration
  def change
    create_table :klines do |t|
      t.integer :base_stock_id
      t.string :symbol
      t.decimal :open, precision: 16, scale: 3
      t.decimal :close, precision: 16, scale: 3
      t.decimal :high, precision: 16, scale: 3
      t.decimal :low, precision: 16, scale: 3
      t.integer :volume, limit: 8
      t.integer :category
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    
    add_index :klines, [:base_stock_id, :category, :start_date], unique: true
  end
end
