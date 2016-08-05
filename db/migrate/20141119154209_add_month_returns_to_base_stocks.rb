class AddMonthReturnsToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :one_month_return, :decimal, :precision => 13, :scale => 8, :default => 0
    add_column :base_stocks, :six_month_return, :decimal, :precision => 13, :scale => 8, :default => 0
    add_column :base_stocks, :one_year_return, :decimal, :precision => 13, :scale => 8, :default => 0
  end
end