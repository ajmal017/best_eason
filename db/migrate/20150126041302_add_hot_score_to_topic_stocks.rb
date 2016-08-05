class AddHotScoreToTopicStocks < ActiveRecord::Migration
  def change
    add_column :topic_stocks, :hot_score, :integer, default: 0
    add_column :topic_stocks, :last_hot_score, :integer, default: 0
    add_index :topic_stocks, :hot_score
  end
end
