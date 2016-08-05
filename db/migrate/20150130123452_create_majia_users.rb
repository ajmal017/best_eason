class CreateMajiaUsers < ActiveRecord::Migration
  def change
    create_table :majia_users do |t|
      t.integer :user_id
      t.string :email
      t.string :password
      t.string :username
      t.boolean :gender
      t.string :province
      t.integer :city
      t.string :headline
      t.string :orientation
      t.string :concern
      t.string :duration
      t.boolean :status, default: false
      t.timestamps
    end
    add_index :majia_users, :user_id
    add_index :majia_users, :email
  end
end
