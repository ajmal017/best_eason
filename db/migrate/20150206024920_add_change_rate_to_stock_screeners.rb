class AddChangeRateToStockScreeners < ActiveRecord::Migration
  def change
    add_column :stock_screeners, :change_rate, :decimal, precision: 10, scale: 6, default: 0
  end
end
