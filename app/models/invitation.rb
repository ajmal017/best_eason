class Invitation < ActiveRecord::Base
  belongs_to :sender, class_name: 'User'
  has_one :recipient, class_name: 'User'

  validates :sender_id, presence: true
  validate :sender_has_invitations, :on => :create, :if => :sender

  before_create :decrement_sender_count, :if => :sender
  def decrement_sender_count
    sender.decrement! :invitation_limit
  end

  before_create :generate_token
  def generate_token
    self.token = 
    loop do
      token = SecureRandom.urlsafe_base64(15).tr('lIO0=\-_', 'sxyzEMU').first(8)
      break token unless self.class.exists?(token: token)
    end
  end
  
  def self.token_valid?(token)
    find_by(token: token).try(:used?) == false
  end

  private

  def sender_has_invitations
    unless sender.invitation_limit > 0
      errors.add(:invitation, '邀请码次数超过限制')
    end
  end
end
