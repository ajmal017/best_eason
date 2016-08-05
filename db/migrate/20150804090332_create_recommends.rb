class CreateRecommends < ActiveRecord::Migration
  def change
    create_table :recommends do |t|
      t.references :staffer
      t.string :status
      t.string :original_url
      t.string :current_url
      t.string :verifiers
      t.string :title
      t.text :content
      t.datetime :published_at

      t.timestamps null: false
    end
  end
end
