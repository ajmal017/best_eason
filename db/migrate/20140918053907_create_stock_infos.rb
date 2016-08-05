class CreateStockInfos < ActiveRecord::Migration
  def change
    create_table :stock_infos do |t|
      t.text :description
      t.string :site
      t.string :telephone
      t.text :profession
      t.string :company_address
      t.integer :base_stock_id
      t.string :symbol

      t.timestamps
    end

  end
end
