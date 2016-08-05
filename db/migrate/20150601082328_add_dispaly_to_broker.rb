class AddDispalyToBroker < ActiveRecord::Migration
  def change
    add_column :brokers, :display, :boolean, default: true
  end
end
