class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.integer :user_id
      t.references :favorable, polymorphic: {limit: 16}
      
      t.timestamps
    end

    add_index :favorites, :user_id
    add_index :favorites, [:favorable_type, :favorable_id]
  end
end
