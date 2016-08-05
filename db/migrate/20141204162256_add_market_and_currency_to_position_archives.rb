class AddMarketAndCurrencyToPositionArchives < ActiveRecord::Migration
  def change
    add_column :position_archives, :market, :string, limit: 10
    add_column :position_archives, :currency, :string, limit: 10
    remove_column :position_archives, :area
  end
end
