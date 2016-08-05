class AddThirtyDaysVolumeAvgToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :thirty_days_volume_avg, :integer, default: 0
  end
end