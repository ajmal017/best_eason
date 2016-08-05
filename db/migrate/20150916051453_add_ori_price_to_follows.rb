class AddOriPriceToFollows < ActiveRecord::Migration
  def change
    add_column :follows, :ori_price, :float
  end
end
