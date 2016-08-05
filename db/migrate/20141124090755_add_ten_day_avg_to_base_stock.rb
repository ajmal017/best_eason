class AddTenDayAvgToBaseStock < ActiveRecord::Migration
  def change
    add_column :base_stocks, :ten_day_avg, :decimal, precision: 16, scale: 2, default: 0.0
  end
end
