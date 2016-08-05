class AddPositionToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :position, :integer

    add_index :brokers, :position
  end
end
