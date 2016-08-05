class ChangeContestOfBaskets < ActiveRecord::Migration
  def change
    change_column :baskets, :contest, :integer, default: 0

    Basket.where(contest: 1).update_all(contest: 2)
  end
end