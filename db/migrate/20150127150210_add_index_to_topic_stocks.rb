class AddIndexToTopicStocks < ActiveRecord::Migration
  def change
    add_index :topic_stocks, [:topic_id, :base_stock_id], unique: true
  end
end
