class CreateTopicArticles < ActiveRecord::Migration
  def change
    create_table :topic_articles do |t|
      t.references :topic
      t.references :article
      t.float :position, default: 10000
      t.boolean :visible, default: true

      t.timestamps
    end
  end
end
