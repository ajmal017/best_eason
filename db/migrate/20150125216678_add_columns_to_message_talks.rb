class AddColumnsToMessageTalks < ActiveRecord::Migration
  def change
    add_column :message_talks, :user_recent_id, :integer
    add_column :message_talks, :subscriber_recent_id, :integer
  end
end
