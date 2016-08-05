class ForbiddenName < ActiveRecord::Base
  validates :word, presence: true, uniqueness: true

  def self.usable?(username)
    self.where(word: username).blank?
  end
end