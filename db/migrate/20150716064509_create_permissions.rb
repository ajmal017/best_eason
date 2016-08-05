class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string :name
      t.string :url
      t.integer :father_id

      t.timestamps null: false
    end
  end
end