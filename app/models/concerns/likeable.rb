module Likeable
  extend ActiveSupport::Concern

  included do
    # 赞功能
    has_many :likes, as: :likeable, class_name: 'Like', dependent: :destroy
    has_many :likers, through: :likes, source: :liker
  end

  def liked_by_user?(user_id)
    return false if user_id.blank?
    self.likes.exists?(:user_id => user_id)
  end

end
