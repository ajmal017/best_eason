class AddPriceToFollows < ActiveRecord::Migration
  def change
    add_column :follows, :price, :float
  end
end