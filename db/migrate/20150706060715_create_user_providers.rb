class CreateUserProviders < ActiveRecord::Migration
  def change
    remove_column :users, :provider_id
    create_table :user_providers do |t|
      t.string  :provider_id, limit: 100
      t.string  :provider, limit: 100
      t.integer :user_id
      t.text    :ext
      t.boolean :active, default: true
    end
    add_index :user_providers, [:provider_id, :provider]
  end
end
