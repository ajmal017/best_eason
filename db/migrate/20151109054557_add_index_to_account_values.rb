class AddIndexToAccountValues < ActiveRecord::Migration
  def change
    remove_index(:account_values, [:user_binding_id, :key, :currency]) if index_exists?(:account_values, [:user_binding_id, :key, :currency])
    add_index :account_values, [:trading_account_id, :key, :currency], unique: true
  end
end
