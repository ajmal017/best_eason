class AddIndexWithoutCashToBasketIndex < ActiveRecord::Migration
  def change
    add_column :basket_indices, :index_without_cash, :decimal, :precision => 10, :scale => 4
  end
end
