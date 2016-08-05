class Feedback < ActiveRecord::Base
  belongs_to :reportable, polymorphic: true
  belongs_to :user

  validates :content, presence: true, if: :suggest?
  #validates :contact_way, presence: true

  enum feed_type: [:suggest, :report]

  FEED_TYPES = {
    0 => "反馈",
    1 => "举报"
  }


end
