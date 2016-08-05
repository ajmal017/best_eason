class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions, force: true do |t|
      t.integer :user_id
      t.integer :feed_id

      t.timestamps null: false
    end
  end
end
