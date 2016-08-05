class AddVolumeTypeOfBaseStock < ActiveRecord::Migration
  def change
    change_column :base_stocks, :three_month_volume_avg, :integer, limit: 8, default: 0
  end
end
