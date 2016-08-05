class AddChannelCodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :channel_code, :string, limit: 100
    add_index :users, :channel_code
  end
end
