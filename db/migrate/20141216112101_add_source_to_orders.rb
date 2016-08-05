class AddSourceToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :source, :string

    add_index :orders, :source
  end

  def self.down
  	remove_column :orders, :source
  end
end