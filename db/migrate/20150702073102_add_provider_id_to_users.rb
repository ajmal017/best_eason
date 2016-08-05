class AddProviderIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :provider_id, :string, limit: 100
    add_index :users, :provider_id, unique: true, name: 'users_by_provider_id'
  end
end
