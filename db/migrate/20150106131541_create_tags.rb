class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags, force: true do |t|
      t.string :name
      t.float :sort, default: 0
      t.string :type
      t.references :user
      t.integer :taggings_count

      t.timestamps
    end

    add_index :tags, :type
  end

  def self.down
    drop_table :tags
  end
end