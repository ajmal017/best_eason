class Landing < ActiveRecord::Base
  validates :email, presence: true, uniqueness: {message: '感谢您的再次关注'}, email: true

  scope :created_at_gte, -> (date_str) { date_str.present? ? where("created_at >= ?", Date.parse(date_str)) : all}
  scope :created_at_lte, -> (date_str) { date_str.present? ? where("created_at <= ?", Date.parse(date_str) + 1) : all}

  after_create :create_lead
  def create_lead
    Lead.find_or_create_by(email: email).update(landing_id: self.id)
  end
end
