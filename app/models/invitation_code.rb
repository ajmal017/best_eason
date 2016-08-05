class InvitationCode < ActiveRecord::Base
  # 大V邀请码最多邀请次数
  MAX_LIMIT = 1000

  validates :code, uniqueness: true

  belongs_to :lead

  before_create :generate_token

  def generate_token
    self.code = 
    loop do
      code = SecureRandom.hex(3).tr('lIO0', 'sxyz')
      break code unless self.class.exists?(code: code)
    end
  end

  def self.code_valid?(code)
    invite_code = find_by(code: code)
    return false if invite_code.blank?

    invite_code.is_a?(InvitationCodeSuper) ?  invite_code.invitation_limit < MAX_LIMIT : invite_code.user_id.nil?
  end
end
