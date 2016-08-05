class AddEmailToUserBrokers < ActiveRecord::Migration
  def change
    add_column :user_brokers, :email, :string
  end
end
