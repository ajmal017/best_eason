class AddSectorToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :sector, :string
    add_column :base_stocks, :industry, :string
  end
end
