class CreateBasketRanks < ActiveRecord::Migration
  def change
    create_table :basket_ranks do |t|
      t.integer :basket_id
      t.float :ret
      t.integer :contest
    end

    add_index :basket_ranks, [:basket_id, :contest]
  end
end
