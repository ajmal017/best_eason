class AddFollowsCount < ActiveRecord::Migration
  def change
    add_column :articles, :follows_count, :integer, default: 0
    add_column :topics, :follows_count, :integer, default: 0
  end
end
