module Countable
  extend ActiveSupport::Concern

  included do
    after_create :increment_unread_counter!
    after_destroy :decrement_unread_counter!

    self.extend ClassMethods
  end

  def increment_unread_counter!
    Counter.find_or_create_by(user_id: user_id).increment!(self.class.counter_field.to_sym)
  end

  def decrement_unread_counter!
    Counter.find_or_create_by(user_id: user_id).decrement!(self.class.counter_field.to_sym) unless self.read?
  end

  module ClassMethods

    def adjust_counter!(user)
      count = user.notifications.where(type: self.name).unread.count
      Counter.find_or_create_by(user_id: user.id).update(self.counter_field.to_sym => count)
    end

    def counter_field
      if self.name == "Notification::StockReminder"
        "unread_stock_reminder_count"
      else
        "unread_#{self.name.demodulize.downcase}_count"
      end
    end

  end

end
