class AddMobileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mobile, :string
    add_column :users, :origin, :string
    add_index :users, :mobile
  end
end
