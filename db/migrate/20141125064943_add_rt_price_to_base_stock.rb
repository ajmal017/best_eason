class AddRtPriceToBaseStock < ActiveRecord::Migration
  def change
    add_column :base_stocks, :rt_price, :decimal, precision: 16, scale: 2, default: 0.0
  end
end
