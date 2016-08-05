class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities, force: true do |t|
      t.integer :user_id
      t.string :type
      t.integer :feed_id
      t.integer :followed_user_id
      t.integer :entry_id
      t.text :content
      t.integer :following_user_id

      t.timestamps null: false
    end
  end
end
