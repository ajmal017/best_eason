class CreateBasketOpinions < ActiveRecord::Migration
  def change
    create_table :basket_opinions do |t|
      t.references :basket
      t.references :user
      t.integer :opinion
      t.datetime :post_time

      t.timestamps
    end

    add_index :basket_opinions, :opinion
  end
end