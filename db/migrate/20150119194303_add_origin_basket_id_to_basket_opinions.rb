class AddOriginBasketIdToBasketOpinions < ActiveRecord::Migration
  def self.up
    add_column :basket_opinions, :original_basket_id, :integer

    add_index :basket_opinions, [:user_id, :basket_id, :original_basket_id], name: "idx_basket_opinions_of_user_basket_original_basket_id"
  end

  def self.down
    remove_column :basket_opinions, :original_basket_id
    remove_index :basket_opinions, name: "idx_basket_opinions_of_user_basket_original_basket_id"
  end
end