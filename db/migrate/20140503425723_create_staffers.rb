class CreateStaffers < ActiveRecord::Migration

  def change
    create_table :staffers do |t|
      t.string :username, null: false
      t.string :encrypted_password, null: false
      t.string :email
      t.string :fullname

      t.boolean :admin, default: false
      t.integer :role_id

      ## Trackable
      t.integer :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      
      ## Confirmable
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      
      t.boolean :deleted

      t.timestamps
    end
    
    add_index :staffers, :username, unique: true
    add_index :staffers, :role_id
  end

end
