class AddBasketsCountToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :baskets_count, :integer, default: 0
  end
end