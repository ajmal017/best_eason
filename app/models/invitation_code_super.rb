class InvitationCodeSuper < InvitationCode
  validates :code, uniqueness: true

  before_create :generate_token, :set_invitation_limit

  private
  def generate_token
    self.code = 
    loop do
      code = SecureRandom.hex(2).tr('lIO0', 'sxyz')
      break code unless self.class.exists?(code: code)
    end
  end

  def set_invitation_limit
    self.invitation_limit = 0
  end
end
