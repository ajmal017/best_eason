class AddMarketAndCurrencyToPositions < ActiveRecord::Migration

  def change
    add_column :positions, :market, :string
    add_column :positions, :currency, :string
  end

end
