class AddStockStateToBasketAdjustLogs < ActiveRecord::Migration
  def change
    add_column :basket_adjust_logs, :stock_state, :integer
  end
end
