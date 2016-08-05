class AddUserIdToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :user_id, :integer

    add_index :basket_ranks, :user_id
  end
end
