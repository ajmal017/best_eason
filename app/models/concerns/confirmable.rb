module Confirmable
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.extend ClassMethods
    klass.class_eval do
      after_create :send_confirmation_email
    end
  end

  module InstanceMethods
    def send_confirmation_email
      if confirmed?
        self.errors.add(:confirmation_token, :actived)
      else
        friendly_token = generate_token(:confirmation_token)
        self.update_columns(confirmation_token: friendly_token, confirmation_sent_at: Time.now.utc)
        send_notification(:confirmation_token)
      end
    end

    def resend_confirmation_email
      send_confirmation_email
    end

    def generate_token(column, length=32)
      loop do
        token = SecureRandom.hex(length)
        break token unless self.class.exists?({ column => token })
      end
    end

    def confirmed?
      confirmed_at.present?
    end

    def confirmation_period_valid?
      confirmation_sent_at && confirmation_sent_at.utc >= 1.weeks.ago
    end

    def reset_confirmation_token!
      self.update_columns(confirmed_at: Time.now.utc, confirmation_token: nil, confirmation_sent_at: nil)
    end

    def send_notification(column)
      ::AccountMailer.send(column, id).deliver
    end

  end

  module ClassMethods
    def check_confirmation_token(token, reset = true)
      user = self.find_or_initialize_by(confirmation_token: token)

      if user.persisted?
        if user.confirmation_period_valid?
          user.reset_confirmation_token! if reset
        else
          user.errors.add(:confirmation_token, :expired)
        end
      end

      user
    end
  end

end
