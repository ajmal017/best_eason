class AddFixedToTopicStocks < ActiveRecord::Migration
  def change
    add_column :topic_stocks, :fixed, :boolean, default: false
    add_index :topic_stocks, [:topic_id, :fixed]
    TopicStock.update_all(fixed: true)
  end
end
