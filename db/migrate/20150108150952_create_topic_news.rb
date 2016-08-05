class CreateTopicNews < ActiveRecord::Migration
  def change
    create_table :topic_news do |t|
      t.string :title
      t.string :url
      t.string :source
      t.datetime :pub_time
      t.references :topic
      t.float :position, default: 10000

      t.timestamps
    end
  end
end