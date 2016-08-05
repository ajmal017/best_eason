class CreateCaDividends < ActiveRecord::Migration
  def change
    create_table :ca_dividends do |t|
      t.string :symbol
      t.string :amount
      t.date :ex_div_date
      t.date :record_date
      t.date :payable_date
      t.integer :base_stock_id
      t.string :company_name

      t.timestamps
    end

  end
end
