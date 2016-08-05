class AddUnreadPositionCountToCounters < ActiveRecord::Migration
  def change
    add_column :counters, :unread_position_count, :integer, default: 0
  end
end
