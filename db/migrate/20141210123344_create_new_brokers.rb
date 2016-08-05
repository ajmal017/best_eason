class CreateNewBrokers < ActiveRecord::Migration
  def change
    create_table :brokers, force: true do |t|
      t.string :name
      t.string :cname
      t.string :status
      t.string :master_account

      t.timestamps
    end

    Broker.create(name: 'unicorn', cname: '益群证券')
    Broker.create(name: 'ib', cname: '盈透证券')
  end
end
