class ChangeThirtyDaysVolumeAvgTypeOfBaseStocks < ActiveRecord::Migration
  def self.up
    change_column :base_stocks, :thirty_days_volume_avg, :integer, limit: 8, default: 0
  end

  def self.down
  end
end
