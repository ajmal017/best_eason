class CreateSuggests < ActiveRecord::Migration
  def up
    create_table :suggests, force: true do |t|
      t.string :title
      t.string :image
      t.integer :article_id

      t.timestamps
    end
  end
  
  def down
    drop_table :suggests
  end
end
