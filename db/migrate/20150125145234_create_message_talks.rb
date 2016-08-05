class CreateMessageTalks < ActiveRecord::Migration
  def change
    create_table :message_talks, force: true do |t|
      t.integer :user_id
      t.integer :subscriber_id
      
      t.integer :recent_id
      
      t.timestamps
    end

    add_index :message_talks, :user_id
    add_index :message_talks, :subscriber_id
  end
end
