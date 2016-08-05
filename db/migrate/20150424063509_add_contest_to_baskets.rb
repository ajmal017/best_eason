class AddContestToBaskets < ActiveRecord::Migration
  def change
    add_column :baskets, :contest, :boolean, default: false, comment: "是否报名参加比赛"

    add_index :baskets, :contest
  end
end