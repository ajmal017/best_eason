class UserCounterCacheWorker
  @queue = :user_counter_cache_worker

  def self.perform(user_id, type)
    user = User.find(user_id)
    
    case type
    when 'Basket'
      user.reset_following_baskets_count
    when 'BaseStock'
      user.reset_following_stocks_count
    when 'CreatedBasket'  #创建的组合数量
      user.reset_baskets_count
    when 'User'
      # FollowedUser
      user.reset_followed_users_count
    when 'FollowingUser'
      user.reset_following_users_count
    end
  end
end