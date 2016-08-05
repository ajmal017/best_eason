class AddFollowingBasketsCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :following_baskets_count, :integer, default: 0
    add_column :users, :following_stocks_count, :integer, default: 0
  end
end
