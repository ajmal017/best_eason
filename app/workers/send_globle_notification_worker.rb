class SendGlobleNotificationWorker
  @queue = :send_globle_notification

  def self.perform(user_id, content, time)
    user = User.find(user_id)
    Notification::Globle.add(user.id, content, time)
  end
end
