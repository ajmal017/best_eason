class AddXigniteSymbolToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :xignite_symbol, :string, limit: 30
    add_index :base_stocks, :xignite_symbol
  end
end
