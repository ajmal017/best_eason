class AddTotalReturnToBaskets < ActiveRecord::Migration
  def self.up
    add_column :baskets, :total_return, :decimal, :precision => 13, :scale => 8
  end

  def self.down
    remove_column :baskets, :total_return
  end
end