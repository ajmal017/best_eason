class AddFollowedUserIdToFollows < ActiveRecord::Migration
  def change
    add_column :follows, :followed_user_id, :integer
  end
end
