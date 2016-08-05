class CreateUserBindings < ActiveRecord::Migration
  def change
    create_table :user_bindings do |t|
      t.integer :user_id
      t.string :broker
      t.string :broker_user_id
      t.integer :status
      t.string :note
      t.boolean :portfolioable
      t.string :base_currency
      t.boolean :available, default: true
      t.integer :count, default: 0
      t.string :updated_by

      t.timestamps
    end

    add_index :user_bindings, [:user_id, :broker], :unique => true
    add_index :user_bindings, :user_id
    add_index :user_bindings, :broker_user_id
  end
end
