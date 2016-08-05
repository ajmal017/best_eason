class AddNotesToTopicStocks < ActiveRecord::Migration
  def change
    add_column :topic_stocks, :notes, :text
  end
end