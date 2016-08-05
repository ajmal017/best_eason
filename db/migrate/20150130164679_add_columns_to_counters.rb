class AddColumnsToCounters < ActiveRecord::Migration
  def change
    add_column :counters, :unread_message_count, :integer, default: 0
    add_column :counters, :unread_mention_count, :integer, default: 0
  end
end
