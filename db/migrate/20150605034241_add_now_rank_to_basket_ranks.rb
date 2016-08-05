class AddNowRankToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :now_rank, :integer
    rename_column :basket_ranks, :prev_day_rank, :prev_rank
    remove_column :basket_ranks, :prev_day
  end
end
