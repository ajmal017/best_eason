class ChangeContestofBasketRanks < ActiveRecord::Migration
  def change
  	rename_column :basket_ranks, :contest, :contest_id
  end
end
