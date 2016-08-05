class AddCurrencyToHistoricalQuotes < ActiveRecord::Migration
  def change
    add_column :historical_quotes, :currency, :string
  end
end
