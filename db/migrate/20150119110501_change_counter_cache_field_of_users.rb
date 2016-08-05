class ChangeCounterCacheFieldOfUsers < ActiveRecord::Migration
  
  def change
    rename_column :users, :followed_users_count, :followed_usersx_count
    rename_column :users, :followers_count, :followersx_count
  end
  
end
