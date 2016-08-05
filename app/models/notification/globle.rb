class Notification::Globle < Notification::Base
  include Countable
  validates :content, presence: true

  def self.add(notice_user_id, content, created_at=nil)
    attributes = { user_id: notice_user_id }
    attributes.merge!(content: content)
    attributes.merge!(created_at: Time.at(created_at)) rescue nil if created_at.present?

    self.create attributes
  end
end
