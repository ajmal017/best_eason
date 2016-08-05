module Accountable
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.extend ClassMethods
  end

  module InstanceMethods

    def password_digest(password)
      Authentication::BCrypt.encrypt(password)
    end

    def send_reset_password
      friendly_token = generate_token(:reset_password_token)

      self.reset_password_token = friendly_token
      self.reset_password_sent_at = Time.now.utc
      self.save(:validate => false)

      send_notification(:reset_password)
    end

    def send_reset_password_with_mobile
      friendly_token = generate_token(:reset_password_token)

      self.reset_password_token = friendly_token
      self.reset_password_sent_at = Time.now.utc
      self.save(:validate => false)
    end

    def send_rebind_email(new_email)
      friendly_token = generate_token(:rebind_email_token)

      self.rebind_email       = new_email
      self.rebind_email_token = friendly_token
      self.rebind_email_sent_at = Time.now.utc
      self.save(:validate => false)

      send_notification(:rebind_email)
    end

    def send_notification(column)
      ::AccountMailer.send(column, id).deliver
    end

    def generate_token(column, length=32)
      loop do
        token = SecureRandom.hex(length)
        break token unless self.class.exists?({ column => token })
      end
    end

    def reset_password_period_valid?
      reset_password_sent_at && reset_password_sent_at.utc >= 1.weeks.ago
    end

    def rebind_email_period_valid?
      rebind_email_sent_at && rebind_email_sent_at.utc >= 1.weeks.ago
    end

    def reset_password!(new_password, new_password_confirmation, clear_token=true)
      self.password = new_password
      self.password_confirmation = new_password_confirmation

      clear_reset_password_token if clear_token

      save(validate: false)
    end

    def reset_password_with_validate!(new_password, new_password_confirmation, clear_token=true)
      self.password = new_password
      self.password_confirmation = new_password_confirmation

      clear_reset_password_token if clear_token

      save!
    end

    def rebind_email!
      self.email = self.rebind_email
      clear_rebind_email_token
      save(validate: false)
    end

    def clear_reset_password_token
      self.reset_password_token = nil
      self.reset_password_sent_at = nil
    end

    def clear_rebind_email_token
      self.rebind_email = nil
      self.rebind_email_token = nil
      self.rebind_email_sent_at = nil
    end

    def send_on_create_confirmation
      resend_confirmation_email
    end

    def resend_confirmation_email
      if confirmed?
        self.errors.add(:confirmation_token, :actived)
      else
        friendly_token = generate_token(:confirmation_token)

        self.confirmation_token = friendly_token
        self.confirmation_sent_at = Time.now.utc
        self.save(:validate => false)

        send_notification(:confirmation_token)
      end
    end

    def confirmed?
      confirmed_at.present?
    end

    def confirmation_period_valid?
      confirmation_sent_at && confirmation_sent_at.utc >= 1.weeks.ago
    end

    def default_set_confirmation!
      self.confirmation_token = generate_token(:confirmation_token)
      self.confirmation_sent_at = Time.now.utc
      self.confirmed_at = Time.now.utc
      self.save(:validate => false)
    end

    def reset_confirmation_token!
      self.confirmed_at = Time.now.utc
      self.confirmation_sent_at = nil
      self.confirmation_token = nil

      self.save(validate: false)
    end

    def valid_password?(password)
      Authentication::BCrypt.decrypt?(password, encrypted_password)
    end

    def valid_current_password?(password)
      ret = valid_password?(password)
      self.errors.add(:current_password, :invalid) unless ret
      ret
    end

  end

  module ClassMethods

    def check_login?(email_or_mobile, password)
      record =
        if email_or_mobile =~ /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
          User.find_by(email: email_or_mobile)
        else
          User.find_by(mobile: email_or_mobile)
        end
      if record && Authentication::BCrypt::decrypt?(password, record.encrypted_password)
        return record
      end
      false
    end

    def reset_password_by_token(attrs = {})
      user = self.find_or_initialize_by(attrs.slice(:reset_password_token))
      
      if user.persisted?
        if user.reset_password_period_valid?
          user.reset_password!(attrs[:password], attrs[:password_confirmation])
        else
          user.errors.add(:reset_password_token, :expired)
        end
      end
      
      user
    end

    def rebind_email_by_token(attrs = {})
      user = self.find_or_initialize_by(attrs.slice(:rebind_email_token))
      
      if user.persisted?
        if user.rebind_email_period_valid?
          user.rebind_email!
        else
          user.errors.add(:rebind_email_token, :expired)
        end
      end
      
      user
    end

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
