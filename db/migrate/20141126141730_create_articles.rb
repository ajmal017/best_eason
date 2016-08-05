class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles, force: true do |t|
      t.string :title
      t.string :img
      t.text :content, :limit => 10485760
      t.date :post_date
      t.string :post_user
      t.string :url
      t.text :remote_img_urls

      t.timestamps
    end
    
    add_index :articles, :title, unique: true
  end
end
