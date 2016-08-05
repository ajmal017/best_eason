class AddUnreadGlobleCountToCounts < ActiveRecord::Migration
  def change
    add_column :counters, :unread_globle_count, :integer, default: 0
  end
end
