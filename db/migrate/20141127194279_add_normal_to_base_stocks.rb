class AddNormalToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :normal, :boolean, default: true
  end
end
