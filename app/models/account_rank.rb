# 账户收益排名数据
class AccountRank < ActiveRecord::Base
  validates_presence_of :user_id, :trading_account_id, :rank_type
  validates :trading_account_id, uniqueness: {scope: [:user_id, :rank_type]}

  RANK_TYPES = %w(day month total)
  CACHE_KEY_PREFIX = "cs:acccount_ranks:"

  belongs_to :user
  belongs_to :broker
  belongs_to :trading_account

  scope :sort, -> { order(percent: :desc, id: :asc) }
  scope :ordered, -> { where(ordered: true) }

  def change_ratio
    percent / 100
  end

  def percent
    pre_open? ? nil : read_attribute(:percent).round(2)
  end

  def real_percent
    read_attribute(:percent)
  end

  # TODO: 前端修改key调用，3、4行为前期给前端输出的数据
  def pretty_json
    {
      user_id: user_id, user_avatar: user.avatar_url(:small), change: profit,
      percent: percent, property: property, username: user.username, ordered: ordered,
      id: user_id, avatar: user.avatar_url(:small),
      amount: property, name: user.username
    }
  end

  def self.top_by(broker_id, rank_type, limit = 20)
    $cache.fetch("#{CACHE_KEY_PREFIX}#{broker_id}_#{rank_type}:top_#{limit}", expires_in: 1.day) do
      where(broker_id: broker_id, rank_type: rank_type).includes(:broker).ordered.sort.includes(:user).limit(20).map(&:pretty_json)
    end
  end

  def self.compare_friends(user, account, rank_type)
    $cache.fetch("#{CACHE_KEY_PREFIX}#{account.id}_#{rank_type}:friends", expires_in: 1.day) do
      user_ids = user.followed_user_ids + [user.id]
      account_ranks = AccountRank.where(broker_id: account.broker_id, rank_type: rank_type, user_id: user_ids).sort.ordered

      ranks = account_ranks.includes(:user, :broker).limit(100).map(&:pretty_json)
      my_rank = AccountRank.where(trading_account_id: account.id, rank_type: rank_type, user_id: user.id).first
      my_percent = my_rank.try(:real_percent) || 0
      my_rankings = account_ranks.where("percent > ? or (percent = ? and id < ?)", my_percent, my_percent, my_rank.id).where.not(user_id: user.id).count + 1 if my_rank.ordered
      prev_rank = account_ranks.where("percent > ? or (percent = ? and id < ?)", my_percent, my_percent, my_rank.id).where.not(user_id: user.id).last if my_rank.ordered
      next_rank = account_ranks.where("percent < ? or (percent = ? and id > ?)", my_percent, my_percent, my_rank.id).where.not(user_id: user.id).first if my_rank.ordered

      [ranks, my_rank, my_rankings, prev_rank, next_rank]
    end
  end

  private

  # 现在模拟账户 A股、美股、港股都是分开的，如果以后遇到多市场的需要进一步处理
  def pre_open?
    Exchange::Base.by_area(broker.market).pre_open?
  end
end
