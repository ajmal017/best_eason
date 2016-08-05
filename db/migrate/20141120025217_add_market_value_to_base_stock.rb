class AddMarketValueToBaseStock < ActiveRecord::Migration
  def change
    add_column :base_stocks, :market_value, :decimal, precision: 20, scale: 3, default: 0.0
  end
end
