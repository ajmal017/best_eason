class CreateBasketWeightLogs < ActiveRecord::Migration
  def change
    create_table :basket_weight_logs do |t|
      t.integer :stock_id
      t.integer :basket_id
      t.decimal :adjusted_weight, :precision => 20, :scale => 18
      t.date :date
    end

    add_index :basket_weight_logs, :basket_id
    add_index :basket_weight_logs, :date
  end
end