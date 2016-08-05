class Like < ActiveRecord::Base
  include Feedable
  
  validates :user_id, presence: true
  validates :likeable_type, :likeable_id, presence: true
  belongs_to :likeable, polymorphic: true, counter_cache: 'likes_count'
  
  belongs_to :liker, class_name: 'User', foreign_key: :user_id
  alias_method :user, :liker

  validates :likeable_id, uniqueness: {scope: [:user_id, :likeable_type], message: '你已经喜欢过了!'}
  
  before_save :set_feed_type, on: [:create]
  after_create :send_notification
  
  def self.add(user_id, likeable)
    create(user_id: user_id, likeable: likeable)
  end

  private
  def send_notification
    send_notice_types = ['Comment']
    if send_notice_types.include?(self.likeable_type)
      return if self.user_id == self.likeable.user_id
      Notification::Like.add(self.likeable.user_id, self.user_id, self.likeable, self) 
    end
  end
  
  def set_feed_type
    self.feed_type = :comment_like
  end
end
