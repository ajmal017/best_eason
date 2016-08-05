class TopicStock < ActiveRecord::Base
  validates :topic_id, :base_stock_id, presence: true
  validates :base_stock_id, uniqueness: {scope: [:topic_id]}

  belongs_to :topic
  belongs_to :base_stock

  scope :fixed, -> {where(fixed: true)}
  scope :float, -> {where(fixed: false)}
  scope :visible, -> {where(visible: true)}

  after_create :update_topic_modified_at
  after_update :update_topic_modified_at, if: -> { self.notes_changed? }

  after_save :update_topic_leading_stocks_count

  def hot_score_change
    "%+d" % (hot_score - last_hot_score)
  end

  def hot_score_up?
    (hot_score - last_hot_score) >= 0
  end

  private
  def update_topic_leading_stocks_count
    self.topic.update_leading_stocks_count if self.visible_changed?
  end

  def update_topic_modified_at
    self.topic.update(modified_at: Time.now)
  end
end
