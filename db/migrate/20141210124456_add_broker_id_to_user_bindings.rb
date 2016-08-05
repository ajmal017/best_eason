class AddBrokerIdToUserBindings < ActiveRecord::Migration
  def change
    remove_column :user_bindings, :broker
    add_column :user_bindings, :broker_id, :integer
  end
end
