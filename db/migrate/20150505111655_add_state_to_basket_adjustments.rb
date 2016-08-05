class AddStateToBasketAdjustments < ActiveRecord::Migration
  def change
    add_column :basket_adjustments, :state, :integer, default: 0

    add_index :basket_adjustments, [:next_basket_id, :state]
  end
end
