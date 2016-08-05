class CreateExchangeRates < ActiveRecord::Migration
  def change
    create_table :exchange_rates do |t|
      t.decimal :value
      t.string :currency
      t.string :account_name
      t.integer :user_binding_id
      t.integer :user_id

      t.timestamps
    end
    
    add_index :exchange_rates, :user_id
    add_index :exchange_rates, :user_binding_id
    add_index :exchange_rates, :account_name
    add_index :exchange_rates, [:currency, :account_name], unique: true
    add_index :exchange_rates, [:currency, :user_id]
    add_index :exchange_rates, [:currency, :user_binding_id]
  end
end
