class AddLeadingStocksCountToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :leading_stocks_count, :integer, default: 0
  end
end