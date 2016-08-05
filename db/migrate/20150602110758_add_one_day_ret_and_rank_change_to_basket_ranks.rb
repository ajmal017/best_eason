class AddOneDayRetAndRankChangeToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :one_day_ret, :float
    add_column :basket_ranks, :prev_day_rank, :integer
    add_column :basket_ranks, :prev_day, :date
    # add_column :basket_ranks, :rank_change, :integer
    add_column :basket_ranks, :status, :integer
  end
end
