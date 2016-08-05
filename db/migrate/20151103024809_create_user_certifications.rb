class CreateUserCertifications < ActiveRecord::Migration
  def change
    create_table :user_certifications do |t|
      t.integer :user_id
      t.string :id_no, null: false, limit: 20
      t.string :real_name, null: false

      t.timestamps
    end

    add_index :user_certifications, :id_no, unique: true
  end
end
