class AddMultiIndexToTopicStocks < ActiveRecord::Migration
  def change
    add_index :topic_stocks, [:base_stock_id, :fixed, :visible], name: 'idx_topic_stocks_bsid_fixed_visible'
  end
end
