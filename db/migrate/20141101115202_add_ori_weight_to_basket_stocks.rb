class AddOriWeightToBasketStocks < ActiveRecord::Migration
  def change
    add_column :basket_stocks, :ori_weight, :decimal, precision: 6, scale: 4
  end
end