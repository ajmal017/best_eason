class AddBuyFrozenToPositions < ActiveRecord::Migration
  def change
    add_column :positions, :buy_frozen, :decimal, precision: 16, scale: 2, default: 0
  end
end
