class AddFollowedUserIdIndexToFollow < ActiveRecord::Migration
  def change
    add_index :follows, :followed_user_id
    remove_index :follows, :following_id
  end
end
