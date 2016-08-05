class AddColumnToUserBrokers < ActiveRecord::Migration
  def change
    add_column :user_brokers, :confirmation_token, :string
    add_column :user_brokers, :confirmation_sent_at, :datetime
  end
end
