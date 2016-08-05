class AddHongbaoToCounter < ActiveRecord::Migration
  def change
    add_column :counters, :unread_hongbao_count, :integer, default: 1
  end
end
