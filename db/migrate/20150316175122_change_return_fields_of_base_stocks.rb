class ChangeReturnFieldsOfBaseStocks < ActiveRecord::Migration
  def change
    change_column :base_stocks, :one_month_return, :float, default: 0
    change_column :base_stocks, :six_month_return, :float, default: 0
    change_column :base_stocks, :one_year_return, :float, default: 0
  end
end