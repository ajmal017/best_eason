class RenameDateToBaseStocks < ActiveRecord::Migration
  def change
    rename_column :base_stocks, :date, :ib_last_date
  end
end
