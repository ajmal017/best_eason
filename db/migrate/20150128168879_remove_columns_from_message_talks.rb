class RemoveColumnsFromMessageTalks < ActiveRecord::Migration
  def change
    remove_column :message_talks, :user_recent_id
    remove_column :message_talks, :subscriber_recent_id
  end
end
