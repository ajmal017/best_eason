class CreateStaticContents < ActiveRecord::Migration
  def change
    create_table :static_contents do |t|
      t.string :sourceable_type, limit: 30
      t.string :sourceable_id, limit: 30
      t.integer :follows_count, default: 0
      t.string :title
      t.text :data

      t.timestamps null: false
    end
    add_index :static_contents, [:sourceable_type, :sourceable_id]
  end
end
