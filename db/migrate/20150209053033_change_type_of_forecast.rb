class ChangeTypeOfForecast < ActiveRecord::Migration
  def change
    change_column :ib_fundamentals, :forecast_xml, :text, limit: 94967295
  end
end
