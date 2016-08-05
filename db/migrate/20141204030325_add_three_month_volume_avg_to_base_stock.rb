class AddThreeMonthVolumeAvgToBaseStock < ActiveRecord::Migration
  def change
    add_column :base_stocks, :three_month_volume_avg, :integer, default: 0
  end
end
