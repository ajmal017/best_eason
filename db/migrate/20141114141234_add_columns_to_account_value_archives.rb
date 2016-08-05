class AddColumnsToAccountValueArchives < ActiveRecord::Migration
  
  def change
    drop_table :account_value_archives

    create_table :account_value_archives do |t|
      t.integer :user_id
      t.string :broker_user_id
      t.string :key
      t.string :currency
      t.decimal :value, precision: 16, scale: 2
      t.integer :user_binding_id
      t.date :archive_date

      t.timestamps
    end

    add_index :account_value_archives, :archive_date
    add_index :account_value_archives, :user_id
  end

end
