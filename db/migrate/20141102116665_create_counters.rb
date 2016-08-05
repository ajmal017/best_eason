class CreateCounters < ActiveRecord::Migration
  def change
    create_table :counters do |t|
      t.integer :user_id
      
      # 未读评论数
      t.integer :unread_comment_count, default: 0 
      # 未读赞数
      t.integer :unread_like_count, default: 0
      # 未读系统通知数
      t.integer :unread_system_count, default: 0
      # 未读交易通知数
      t.integer :unread_trade_count, default: 0

      t.timestamps
    end

    add_index :counters, :user_id, unique: true
  end
end
