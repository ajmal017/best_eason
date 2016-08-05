class CreateBasketIndices < ActiveRecord::Migration
  def change
    create_table :basket_indices do |t|
      t.integer :basket_id
      t.date :date
      t.decimal :index, :precision => 10, :scale => 4

      t.timestamps
    end
    
    add_index :basket_indices, :basket_id
    add_index :basket_indices, :date
  end
end
