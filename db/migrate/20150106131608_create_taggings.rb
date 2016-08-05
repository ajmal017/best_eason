class CreateTaggings < ActiveRecord::Migration
  def self.up
    create_table :taggings, force: true do |t|
      t.references :tag
      t.references :taggable, polymorphic: {limit: 16}

      t.timestamps
    end

    add_index :taggings, [:taggable_id, :taggable_type]
  end

  def self.down
    drop_table :taggings
  end
end