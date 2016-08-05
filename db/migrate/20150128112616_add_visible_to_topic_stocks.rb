class AddVisibleToTopicStocks < ActiveRecord::Migration
  def change
    add_column :topic_stocks, :visible, :boolean, default: false
  end
end