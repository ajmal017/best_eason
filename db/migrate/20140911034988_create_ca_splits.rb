class CreateCaSplits < ActiveRecord::Migration
  def change
    create_table :ca_splits do |t|
      t.string :symbol
      t.string :factor
      t.integer :base_stock_id
      t.string :company_name
      t.date :date
      t.boolean :finished, default: false    
      
      t.timestamps
    end

    add_index :ca_splits, :base_stock_id
    add_index :ca_splits, :symbol
  end
end
