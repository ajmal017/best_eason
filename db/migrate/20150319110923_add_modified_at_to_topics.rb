class AddModifiedAtToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :modified_at, :datetime
    Topic.all.each{|topic| topic.update(modified_at: topic.created_at) }
  end
end
