class AddBasketFluctuationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :basket_fluctuation, :decimal, precision: 20, scale: 8, default: 0
  end
end
