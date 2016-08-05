class ApiToken < ActiveRecord::Base
  before_create :generate_access_token
  before_create :set_expiration
  belongs_to :user

  # token过期天数
  EXPIRES_DAYS = 360

  def expired?
    Time.now >= self.expires_at
  end
  
  def refresh_expires_at!
    self.update(expires_at: Time.now + EXPIRES_DAYS.days)
  end

  def refresh_self!(attrs={})
    set_expiration
    generate_access_token

    attrs.each do|k, v|
      self.send("#{k}=", v) if self.respond_to?("#{k}=")
    end

    self.save!
  end

  def self.expire_all(user_id)
    self.where(user_id: user_id).update_all(expires_at: 1.days.ago)
  end

  private
  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(access_token: access_token)
  end

  def set_expiration
    self.expires_at = Time.now + EXPIRES_DAYS.days
  end
end
