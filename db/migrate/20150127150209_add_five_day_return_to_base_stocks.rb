class AddFiveDayReturnToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :five_day_return, :float
  end
end