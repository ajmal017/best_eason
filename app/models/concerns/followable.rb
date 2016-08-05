module Followable
  extend ActiveSupport::Concern
  included do
    # follow对象，粉丝
    has_many :follows, as: :followable, class_name: 'Follow::Base', dependent: :destroy
    # 粉丝，user对象
    has_many :followers, -> { order "follows.created_at DESC" }, through: :follows, source: :user
  end

  def follow_by_user(user_id)
    klass = "Follow::#{{base_stocks: :Stock}[self.class.table_name.to_sym] || self.class.table_name.singularize.classify}".constantize
    klass.create(user_id: user_id, followable: self)
  end

  def unfollow_by_user(user_id)
    self.follows.where(user_id: user_id).destroy_all
  end

  def followed_by_user?(user_id)
    user_id.present? && self.follows.where(user_id: user_id).present?
  end

  def get_follow(user_id)
    self.follows.where(user_id: user_id).first
  end

  def follow_or_unfollow_by_user(user_id)
    if followed_by_user?(user_id)
      unfollow_by_user(user_id)
      return false
    else
      follow_by_user(user_id)
      return true
    end
  end
end
