class AddPositionPercentToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :position_percent, :float, default: 0
    add_column :basket_ranks, :win_rate, :float, default: 0
  end
end
