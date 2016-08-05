class CreateSymbolChangeLogs < ActiveRecord::Migration
  def change
    create_table :symbol_change_logs do |t|
      t.integer :base_stock_id
      t.string :field
      t.string :log
      t.string :log_type

      t.timestamps
    end
  end
end
