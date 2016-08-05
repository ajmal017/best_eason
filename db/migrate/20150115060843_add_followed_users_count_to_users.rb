class AddFollowedUsersCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :followed_users_count, :integer, default: 0
  end
end
