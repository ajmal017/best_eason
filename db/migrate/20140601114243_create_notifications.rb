class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      # 接收通知用户
      t.belongs_to :user, index: true
      # @类型
      t.belongs_to :mentionable, polymorphic: true, index: true
      # 是否已读
      t.boolean :read, default: false
      # 通知类型
      t.string :type, limit: 32, index: true
      
      t.belongs_to :originable, polymorphic: true, index: true
      
      t.text :content
      t.integer :triggered_user_id
      
      t.timestamps
    end
    
    add_index :notifications, :read
  end
end
