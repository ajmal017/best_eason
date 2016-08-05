class AddMarketAndCurrencyToOrderDetails < ActiveRecord::Migration

  def change
    add_column :order_details, :market, :string
    add_column :order_details, :currency, :string
  end

end
