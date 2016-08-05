module PushNotification
  extend ActiveSupport::Concern

  included do
    after_create :jpush
  end

  def jpush
    # 如果没有push_content方法，直接使用content进行推送
    content = self.try(:push_content) || self.content
    JpushPublisher.publish({type: "alias", alias: self.user_id, content: content, mentionable_type: self.mentionable_type_map, mentionable_id: self.mentionable_id})
  rescue
    Rails.logger.error "Notification ID #{self.id}: jpush failed"
  end

end
