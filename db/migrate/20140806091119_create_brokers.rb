class CreateBrokers < ActiveRecord::Migration
  def change
    create_table :brokers do |t|
      t.string :master_account
      t.string :symbol

      t.timestamps
    end
  end
end
