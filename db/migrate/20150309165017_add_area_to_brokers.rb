class AddAreaToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :area, :string, limit: 10
    change_column :brokers, :status, :string, limit: 10, default: :new
    add_index :brokers, :area
  end
end
