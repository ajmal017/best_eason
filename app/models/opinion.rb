class Opinion < ActiveRecord::Base

  OPINIONS = {"up" => 1, "down" => 2}
  WHITE_TYPES = %w(BaseStock Basket)

  validates :user_id, presence: true, uniqueness: {scope: [:opinionable_type, :opinionable_id]}

  belongs_to :user
  belongs_to :opinionable, polymorphic: true

  scope :bullished, -> {where(:opinion => OPINIONS["up"])}
  scope :bearished, -> {where(:opinion => OPINIONS["down"])}
  scope :in_one_month, -> {where("post_time >= ?", 1.month.ago)}
  scope :by_opinionable, ->(opinionable) { where(opinionable: opinionable) }
  scope :by_type, ->(type) { where(opinionable_type: type) }

  after_save :set_bullish_percent

  def self.set_opinion(opinion_symbol, opinionable, user_id)
    opinion = self.find_or_initialize_by(opinionable: opinionable, user_id: user_id)
    opinion.update(opinion: OPINIONS[opinion_symbol], post_time: Time.now)
  end

  def self.setted_up?(opinionable, user_id)
    opinion = self.find_by(opinionable: opinionable, user_id: user_id)
    opinion && opinion.up?
  end

  def self.setted_down?(opinionable, user_id)
    opinion = self.find_by(opinionable: opinionable, user_id: user_id)
    opinion && opinion.down?
  end

  def self.one_month_bullish_count(opinionable)
    by_opinionable(opinionable).bullished.in_one_month.count
  end

  def self.one_month_bearish_count(opinionable)
    by_opinionable(opinionable).bearished.in_one_month.count
  end

  def self.opinioners_by(opinionable, type = nil)
    opinions = by_opinionable(opinionable).in_one_month
    opinions = type == "bullished" ? opinions.bullished : opinions.bearished if type.present?
    opinions.includes(:user).group("user_id").select("user_id, max(updated_at) n_updated_at")
            .order("n_updated_at desc").limit(24).map(&:user)
  end

  def self.opinioners_count(opinionable)
    by_opinionable(opinionable).in_one_month.select("distinct user_id").count
  end

  def self.opinionables_by_opinioners_count(type = 'BaseStock')
    self.by_type(type).includes(:opinionable).in_one_month.group(:opinionable_type, :opinionable_id)
        .select("opinionable_id, opinionable_type, count(*) as opinion_count")
        .order("opinion_count desc").limit(5).map(&:opinionable).compact
  end

  def up?
    opinion == OPINIONS["up"]
  end

  def down?
    opinion == OPINIONS["down"]
  end

  private
  def set_bullish_percent
    opinionable.set_bullish_percent
  end

end