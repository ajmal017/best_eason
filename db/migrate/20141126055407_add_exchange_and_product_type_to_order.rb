class AddExchangeAndProductTypeToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :exchange, :string
    add_column :orders, :product_type, :string
    add_column :orders, :market, :string
  end
end
