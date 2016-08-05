class AddRealtimeWeightFromToBasketAdjustLogs < ActiveRecord::Migration
  def change
    add_column :basket_adjust_logs, :realtime_weight_from, :decimal, :precision => 8, :scale => 6
    add_column :basket_stock_snapshots, :change_percent, :float, default: 0
  end
end