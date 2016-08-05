class AddPnlToPositions < ActiveRecord::Migration
  def change
    add_column :positions, :pnl, :decimal, precision: 16, scale: 2
    add_column :positions, :today_pnl, :decimal, precision: 16, scale: 2
  end
end
