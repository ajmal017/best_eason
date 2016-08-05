class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds, force: true do |t|
      t.string :title
      t.string :url
      t.string :feed_url
      
      t.timestamps
    end
  end
end
