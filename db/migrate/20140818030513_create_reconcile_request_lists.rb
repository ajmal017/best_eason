class CreateReconcileRequestLists < ActiveRecord::Migration
  def change
    create_table :reconcile_request_lists do |t|
      t.integer :user_id
      t.string :broker_user_id
      t.text :symbol
      t.integer :count
      t.string :updated_by

      t.timestamps
    end
    
    add_index :reconcile_request_lists, :user_id, :unique => true
  end
end
