module Mentionable
  extend ActiveSupport::Concern
  included do
    attr_accessor :mentioned_user_ids

    before_save :extract_mentioned_users
    after_create :create_notification_mention, if: "self.mentioned_user_ids"
    after_destroy :delete_notification_mentions

    has_many :notification_mentions, as: :mentionable, class_name: 'Notification::Mention'
  end

  def extract_mentioned_users
    usernames = text.scan(/@([^\s|^@]+)/).flatten
    if usernames.present?
      self.mentioned_user_ids = User.select(:id).where(username: usernames).limit(50).map(&:id)
    end
  end

  def delete_notification_mentions
    Notification::Mention.where(originable_id: self.id, originable_type: self.class.name).destroy_all
  end
end
