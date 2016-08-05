class AddCommentsCountToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :comments_count, :integer, default: 0
  end

end
