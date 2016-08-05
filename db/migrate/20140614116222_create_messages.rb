class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      # 发送者
      t.integer :sender_id
      # 接收者
      t.integer :receiver_id
      # 所属谈话
      t.integer :talk_id
      # 是否已读
      t.boolean :read, default: false
      t.text :content

      t.timestamps
    end

    add_index :messages, :sender_id
    add_index :messages, :receiver_id
  end
end
