class AddTypeToBaseStocks < ActiveRecord::Migration
  def change
    add_column :base_stocks, :type, :string
    add_index :base_stocks, :type
  end
end