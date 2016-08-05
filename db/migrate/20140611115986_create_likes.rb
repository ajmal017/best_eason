class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.integer :user_id
      t.integer :feed_id
      
      t.references :likeable, polymorphic: {limit: 16}

      t.timestamps
    end
    
    add_index :likes, [:likeable_id, :likeable_type]
    add_index :likes, :user_id
    add_index :likes, :feed_id
  end
end
