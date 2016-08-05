class AddAdjustCountToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :adjust_count, :integer, default: 0
  end
end
