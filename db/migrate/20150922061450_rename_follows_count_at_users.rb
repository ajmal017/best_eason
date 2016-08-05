class RenameFollowsCountAtUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :followings_count
    rename_column :users, :followersx_count, :follows_count
    rename_column :users, :followed_usersx_count, :followed_users_count
  end

  def self.down
    add_column :users, :followings_count, :integer
    rename_column :users, :follows_count, :followersx_count
    rename_column :users, :followed_users_count, :followed_usersx_count
  end
end
