class CreateAccountValues < ActiveRecord::Migration
  def change
    create_table :account_values do |t|
      t.integer :user_id
      t.string :broker_user_id
      t.string :key
      t.string :currency
      t.decimal :value, precision: 16, scale: 2
      t.integer :user_binding_id

      t.timestamps
    end
    
    add_index :account_values, [:user_binding_id, :key, :currency], :unique => true
  end
end
