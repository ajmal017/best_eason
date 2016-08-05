class AddUnreadStockReminderCountToCounters < ActiveRecord::Migration
  def change
    add_column :counters, :unread_stock_reminder_count, :integer, default: 0
  end
end
