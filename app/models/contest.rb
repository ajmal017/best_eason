class Contest < ActiveRecord::Base
  include Commentable

  STATUS_NAMES = ['编辑中', '进行中', '已结束']
  enum status: [:init ,:running, :finished]

  belongs_to :broker
  has_many :players
  has_many :basket_ranks

  alias_attribute :title, :name
  # mount_uploader :players_csv, ContestPlayerUploader
  attr_accessor :players_area
  
  after_save :import, if: :players_area
  # after_save :set_contest_cash
  after_save :unaudit_players_account, if: ->{ finished? && status_changed? } 

  def unaudit_players_account
    players.map(&:unaudite_account)
  end

  def set_contest_cash(cash)
    $redis.set('contest_cash', cash.to_f)
  end

  def bonus
    $redis.get('contest_cash')
  end

  def bonus_sync_at
    Time.at($redis.get('contest_timestamp').to_i)
  end

  def status_name
    STATUS_NAMES[attributes['status']]
  end

  def self.status_options
    statuses.map{|k,v| [STATUS_NAMES[v], k]}
  end

  def import
    errors = {}
    num = 0
    count = 0
    players_area.each_line do |line|
      cs_id, broker_no = line.chop.split(',')
      cs_id = cs_id.to_i
      logger.info "cs_id = #{cs_id}; broker_no = '#{broker_no}'"
      next if cs_id == 0
      count+=1
      flag,player = Player.create_by_import(cs_id, id, broker_no)
      if flag
        num+=1
      else
        errors[broker_no] = player.errors.full_messages + player.trading_account.errors.full_messages
      end
    end
    { count: count, imported: num, errors: errors }
  end

  # todo: 创建前3个contest并做对应
  def latest_order_details(limit = 10, last_id = nil)
    order_details = if last_id.blank?
        OrderDetail
      else
        detail = OrderDetail.find_by_id(last_id)
        OrderDetail.where("trade_time > ?", detail.trade_time)
      end
    order_details.includes(:stock, :user).where("real_shares>0").account_with(account_ids).trade_time_desc.limit(limit)
        .select(:id, :base_stock_id, :user_id, :real_shares, :real_cost, :trade_time, :trade_type)
  end

  def buy_most_stocks
    $cache.fetch("contest_buy_most:#{id}", :expires_in => 1.minutes){ top_stocks_of("buy") }
  end

  def sell_most_stocks
    $cache.fetch("contest_sell_most:#{id}", :expires_in => 1.minutes){ top_stocks_of("sell") }
  end

  def virtual_rank(ret)
    BasketRank.virtual_rank(id, ret)
  end

  def avg_ret
    $cache.fetch("contest_avg_ret:#{id}", :expires_in => 5.minutes){ BasketRank.avg_ret(id) }
  end

  def search_rank(page = 1, per_page = 20)
    BasketRank.search(id, page, per_page)
  end

  def player_of(user_id)
    players.by_user(user_id).first
  end

  def basket_rank_of(user_id)
    return nil if user_id.blank?
    basket_ranks.by_user(user_id).first
  end

  def basket_id_of(user_id)
    basket_rank_of(user_id).try(:basket_id)
    # $cache.fetch("contest:#{id}:basket_id_by_user:#{user_id}", expires_in: 1.minutes) do
    #   basket_rank_of(user_id).try(:basket_id)
    # end
  end

  def basket_most_followed
    $cache.fetch("contest:#{id}:basket_most_followed", expires_in: 2.minutes) do
      Basket.normal.finished.where(contest: id).order(follows_count: :desc).limit(1).first
    end
  end

  def user_most_followed
    $cache.fetch("contest:#{id}:user_most_followed", expires_in: 2.minutes) do
      User.where(id: user_ids).order(follows_count: :desc).limit(1).first
    end
  end

  def sign_next_contest(user_id)
    PreContestant.create(user_id: user_id, contest_id: id)
  end

  def signed_next?(user_id)
    PreContestant.where(user_id: user_id, contest_id: id).select(:id).present?
  end

  private
  def normal_players
    @normal_players ||= players.normal.select(:trading_account_id, :user_id)
  end

  def account_ids
    normal_players.map(&:trading_account_id)
  end

  def user_ids
    normal_players.map(&:user_id)
  end

  # todo: 暂时只考虑A股大赛，美股+港股大赛需另行处理
  def exchange
    @exchange ||= Exchange::Base.by_area(:cn)
  end

  def trade_time_ranges
    @trade_time_ranges ||= exchange.prev_latest_workday_time_range
  end

  def top_stocks_of(type)
    order_details = OrderDetail.has_filled.account_with(account_ids)
    order_details = type == "buy" ? order_details.buyed : order_details.selled
    stock_ids = order_details.trade_time_range(trade_time_ranges[0], trade_time_ranges[1])
                    .select(:base_stock_id).group(:user_id, :base_stock_id)
                    .order("count(user_id) desc, sum(real_shares) desc").limit(4).map(&:base_stock_id)
    BaseStock.where(id: stock_ids)
  end
end
