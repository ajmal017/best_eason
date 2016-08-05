class UserProvider < ActiveRecord::Base
  belongs_to :user
  scope :actived, -> { where active: true }

  def nick_name
    @nick_name ||= JSON.parse(ext).fetch("nickname") rescue nil
  end
end
