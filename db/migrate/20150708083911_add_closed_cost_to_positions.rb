class AddClosedCostToPositions < ActiveRecord::Migration
  def change
    add_column :positions, :closed_cost, :decimal, precision: 20, scale: 4, comment: "平仓时成本价"
  end
end
