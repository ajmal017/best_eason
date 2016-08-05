class AddSummaryToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :summary, :text
  end
end