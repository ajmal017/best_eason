class MessageTalk < ActiveRecord::Base
  validates :user_id, presence: true
  validates :subscriber_id, presence: true

  belongs_to :user
  belongs_to :subscriber, class_name: :User
  
  has_one :recent_message, class_name: :Message, primary_key: :recent_id, foreign_key: :id

  has_many :messages
  def messages
    Message.where(foreign_key => self.id).order(id: :desc)
  end

  scope :except_recent_blank, -> { where.not(recent_id: nil) }
  
  # 重置最近消息ID
  def reset_recent_msg_id(except_id = nil)
    self.messages.without(except_id).blank? ? self.destroy : self.update(recent_id: self.messages.without(except_id).first.id)
  end

  # 清空某人的谈话列表
  def clear
    self.messages.update_all(foreign_key => nil, read: true) && self.destroy
    Message.adjust_counter!(self.user_id)
  end

  def self.fetch_by(user_id, subscriber_id)
    self.find_or_create_by(user_id: user_id, subscriber_id: subscriber_id)
  end

  def self.talks_of(user_id)
    self.where(user_id: user_id).except_recent_blank
        .includes(:subscriber, :recent_message).order(updated_at: :desc)
  end

  private
  def foreign_key
    user_id < subscriber_id ? :user_talk_id : :subscriber_talk_id
  end
end
