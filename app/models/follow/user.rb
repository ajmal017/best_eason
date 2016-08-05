class Follow::User < Follow::Base
  before_create :set_friend
  before_destroy :unfriendly

  def self.followed_user_ids(user_id)
    by_user(user_id).pluck(:followable_id) - [user_id]
  end

  # 共同关注的人ids
  def self.both_followed_user_ids(user, other_user)
    sql = "select followable_id from follows where user_id in (#{user.id},#{other_user.id}) and followable_type='User' group by followable_id having count(followable_id)>1"
    find_by_sql(sql).map(&:followable_id)
  end

  private

  def set_friend
    friend = self.class.find_by(user_id: self.followable_id, followable_id: self.user_id)
    if friend
      self.friend = true
      friend.update_attributes(friend: true)
    end
  end

  def unfriendly
    friend = self.class.find_by(user_id: self.followable_id, followable_id: self.user_id)
    if friend
      friend.update_attributes(friend: false)
    end
  end

  # def followings_counter_cache
  #   Resque.enqueue(UserCounterCacheWorker, user_id, "FollowedUser")
    # Resque.enqueue(UserCounterCacheWorker, followable_id, "FollowingUser")
  # end
end