class Message < ActiveRecord::Base
  belongs_to :sender, class_name: :User, foreign_key: :sender_id
  belongs_to :receiver, class_name: :User, foreign_key: :receiver_id

  belongs_to :user_talk, class_name: :MessageTalk, foreign_key: :user_talk_id
  belongs_to :subscriber_talk, class_name: :MessageTalk, foreign_key: :subscriber_talk_id

  validates :content, presence: {message: "请填写内容"}, sensitive: true

  scope :unread, -> { where(read: false) }
  scope :desc_id, -> { order(id: :desc) }
  scope :without, -> (id) { where.not(id: id) }
  
  before_create :change_content
  def change_content
    self.content = Caishuo::Utils::Text.auto_link_stocks(self.content)
    self.content = Caishuo::Utils::Text.replace_emoji(self.content.html_safe)
  end
  
  def self.add(sender_id, receiver_id, content)
    create(sender_id: sender_id, receiver_id: receiver_id, content: content) 
  end

  before_create :set_talk_id
  def set_talk_id
    self.user_talk_id, self.subscriber_talk_id = fetch_user_talk_id, fetch_subscriber_talk_id
  end
  
  def fetch_user_talk_id
    fetch_talks.find{|m| m.user_id <= m.subscriber_id }.id
  end

  def fetch_subscriber_talk_id
    fetch_talks.find{|m| m.user_id >= m.subscriber_id }.id
  end

  def fetch_talks
    @user_talk ||= MessageTalk.fetch_by(sender_id, receiver_id)
    @subscriber_talk ||= MessageTalk.fetch_by(receiver_id, sender_id)
    
    [@user_talk, @subscriber_talk]
  end

  after_create :update_talk_recent
  def update_talk_recent
    MessageTalk.where(id: [user_talk_id, subscriber_talk_id]).update_all(recent_id: self.id, updated_at: Time.now)
  end

  # 删除单条微博
  def soft_delete(talk_id)
    talk(talk_id).reset_recent_msg_id(self.id) if need_reset_id?(talk_id)
    
    self.update(talk_foreign_key_by(talk_id) => nil)
  end

  def need_reset_id?(talk_id)
    talk(talk_id).try(:recent_id) == self.id
  end

  def talk_foreign_key_by(talk_id)
    talk_id.to_i == user_talk_id ? :user_talk_id : :subscriber_talk_id
  end

  def talk(talk_id)
    talk_id.to_i == user_talk_id ? user_talk : subscriber_talk
  end

  def receiver_talk_id
    sender_id <= receiver_id ? self.subscriber_talk_id : self.user_talk_id
  end

  #===========Counter============
  after_create :increment_counter!
  def increment_counter!
    Counter.find_or_create_by(user_id: receiver_id).increment!(:unread_message_count)
  end

  def self.adjust_counter!(user_id, count = nil)
    unread_count = count || MessageTalk.where(id: self.where(receiver_id: user_id).unread.map(&:receiver_talk_id).uniq).count 
    Counter.find_or_create_by(user_id: user_id).update(unread_message_count: unread_count)
  end

  private
end
