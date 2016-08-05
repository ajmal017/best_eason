class CreateUserBrokers < ActiveRecord::Migration
  def change
    create_table :user_brokers do |t|
      t.integer :user_id
      t.integer :broker_id
      t.string  :broker_no
      t.integer :status

      t.timestamps 
    end
  end
end
