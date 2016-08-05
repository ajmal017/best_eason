class ChangeUserBrokers < ActiveRecord::Migration
  def change
    change_column :user_brokers, :broker_id, :string
  end
end
