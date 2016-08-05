class AddBullishPercentToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :bullish_percent, :float, default: 0
    add_column :base_stocks, :bearish_percent, :float, default: 0
  end
end