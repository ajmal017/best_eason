class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics, force: true do |t|
      t.string :title
      t.string :market
      t.text :notes
      t.string :img
      t.integer :author_id
      t.float :position, default: 0
      t.integer :views_count, default: 0
      t.string :basket_ids

      t.timestamps
    end

    add_index :topics, :author_id
    add_index :topics, :market
  end

  def self.down
    drop_table :topics
  end
end