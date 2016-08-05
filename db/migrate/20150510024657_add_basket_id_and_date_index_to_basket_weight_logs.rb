class AddBasketIdAndDateIndexToBasketWeightLogs < ActiveRecord::Migration
  def change
    add_index :basket_weight_logs, [:basket_id, :date]
  end
end
