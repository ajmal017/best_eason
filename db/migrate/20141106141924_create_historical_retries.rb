class CreateHistoricalRetries < ActiveRecord::Migration
  def change
    create_table :historical_retries do |t|
      t.integer :base_stock_id
      t.string :symbol
      t.date :date

      t.timestamps 
    end

    add_index :historical_retries, :base_stock_id
    add_index :historical_retries, :symbol
    add_index :historical_retries, :date
  end
end
