class ChangeStructToMessages < ActiveRecord::Migration
  def change
    remove_column :messages, :deleted_user_id
    remove_column :messages, :talk_id

    add_column :messages, :user_talk_id, :integer
    add_column :messages, :subscriber_talk_id, :integer

    add_index :messages, :user_talk_id
    add_index :messages, :subscriber_talk_id
  end
end
