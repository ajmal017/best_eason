class AddRealShareToBasketStocks < ActiveRecord::Migration
  def change
    add_column :basket_stocks, :real_share, :integer, default: 0
  end
end