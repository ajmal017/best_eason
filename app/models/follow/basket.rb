class Follow::Basket < Follow::Base

  def return_from_follow
    followable.newest_version.cal_return_from(self.created_at.to_date)
  end

  def self.followed_baskets_by(user_id)
    self.includes(followable: [:author]).by_user(user_id).sort
  end

end