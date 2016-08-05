class AddClosePriceToPositionArchives < ActiveRecord::Migration

  def change
    add_column :position_archives, :close_price, :decimal, precision: 16, scale: 3
  end

end
