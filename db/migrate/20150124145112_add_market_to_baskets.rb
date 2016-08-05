class AddMarketToBaskets < ActiveRecord::Migration
  def change
    add_column :baskets, :market, :string
    add_index :baskets, :market
  end
end