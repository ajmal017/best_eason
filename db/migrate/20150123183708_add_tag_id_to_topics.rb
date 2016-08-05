class AddTagIdToTopics < ActiveRecord::Migration
  def self.up
    add_column :topics, :tag_id, :integer
    change_column :tags, :taggings_count, :integer, default: 0
  end

  def self.down
    remove_column :topics, :tag_id, :integer
    change_column :tags, :taggings_count, :integer, default: 0
  end
end