class BasketRank < ActiveRecord::Base
  CONTESTS = {1 => "511-522A股大赛", 3 => "616-实盘大赛"}
  SHIPAN_CONTESTS = [3]

  STATUS = {runing: 1, liquidated: 2, warning: 3, ended: 4}
  STATUS_DESC = {1 => "实盘进行中", 2 => "已被斩仓", 3 => "达到预警线", 4 => "比赛结束"}
  STATUS_COLORS = {1 => "#0065ca", 2 => "#49b079", 3 => "#ff7800", 4 => "#e4462e"}

  validates :basket_id, uniqueness: {scope: [:contest_id]}

  scope :by_contest, ->(contest_id) { where(contest_id: contest_id)}
  scope :day_ret_desc, -> { order(one_day_ret: :desc) }
  scope :ret_desc, -> { where("ret is not null").order(ret: :desc, id: :asc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :runing, -> { where(status: STATUS[:runing]) }
  scope :account_with, -> (account_id) { where(trading_account_id: account_id) }

  belongs_to :basket
  belongs_to :contest
  belongs_to :user
  belongs_to :trading_account

  # def self.copy_contest_1
  #   basket_ids_with_score = Redis::SortedSet.new("cache:basket_rank").revrange(0, -1, with_scores: true)
  #   basket_ids_with_score.in_groups_of(20, false).each do |ranks|
  #     basket_ranks = ranks.map do |basket_id, rank|
  #       BasketRank.new(basket_id: basket_id, ret: rank, contest: 1)
  #     end
  #     BasketRank.import(basket_ranks, validate: true)
  #   end
  #   Basket.normal.contest.where.not(id: BasketRank.contest_1_top(50).keys).update_all(contest: false)
  # end

  def status_desc
    STATUS_DESC[status]
  end

  def status_color
    STATUS_COLORS[status]
  end

  def can_set_ret?
    [STATUS[:runing], STATUS[:warning]].include?(status)
  end

  def out?
    [STATUS[:liquidated], STATUS[:ended]].include?(status)
  end

  def realtime_total_ret
    out? ? ret.to_f : trading_account.try(:total_profit_percent)
  end

  def self.contest_1_count
    init_count = $redis.get("virtual_contest_participants_count") || 0
    by_contest(1).count + init_count.to_i
  end

  def self.contest_1_top(limit)
    top(1, limit)
  end

  def self.top(contest_id, limit)
    by_contest(contest_id).order(ret: :desc).limit(limit).select(:basket_id, :ret)
      .map{|x| [x.basket_id, x.ret]}.to_h
  end

  def self.load_shipan_ret(contest_id)
    return unless SHIPAN_CONTESTS.include?(contest_id) && ClosedDay.is_workday?(Date.today, :cn)

    by_contest(contest_id).find_each do |br|
      br.set_rets
    end

    record_prev_ranks(contest_id)
  end

  #把上一次最终排名计入prev_rank
  def self.record_prev_ranks(contest_id)
    ranks = by_contest(contest_id).ret_desc.select(:id, :now_rank).map{|br| [br.id, br.now_rank]}
    rank_ids = ranks.map{|x| x[0]}
    ranks.in_groups_of(20, false).each do |ranks_group|
      basket_ranks = ranks_group.map do |id, now_rank|
        [id, rank_ids.index(id)+1, now_rank]
      end
      BasketRank.import(%w(id now_rank prev_rank), basket_ranks, validate: false, on_duplicate_key_update: [:now_rank, :prev_rank])
    end
  end

  def set_rets
    self.status = status_by_ret
    return unless can_set_ret?
    self.ret = get_total_ret
    update(analysis_infos.merge(one_day_ret: basket.shipan_ret_percent))
  end

  def ret_with_status
    if status == STATUS[:warning]
      [ret.to_f,-10].min
    elsif status == STATUS[:liquidated]
      [ret.to_f,-15].min
    else
      ret
    end
  end

  def get_total_ret
    return nil unless trading_account.present?
    trading_account.valid_orders_count>0 ? basket.shipan_total_ret_percent : nil
  end

  def set_analysis_infos
    self.update(analysis_infos)
  end

  def analysis_infos
    {
      position_percent: trading_account.try(:position_percent), adjust_count: trading_account.valid_orders_count, 
      win_rate: trading_account.try(:win_rate), status: status_by_ret
    }
  end

  def status_by_ret
    return status unless in_runing?
    return STATUS[:liquidated] if trading_account.out?
    ret && ret < -10 ? STATUS[:warning] : STATUS[:runing]
  end

  def set_status!
    update(status: status_by_ret)
    frozen_ret
  end

  def frozen_ret
    return unless out?
    player = Player.where(contest_id: contest_id, trading_account_id: trading_account_id).last
    return if player.ret.present?
    
    total_ret = basket.shipan_total_ret_percent
    player.update(ret: total_ret)
    update(ret: total_ret)
  end

  def in_runing?
    [1, 3].include?(status)
  end

  # 排名变化
  def rank_change
    prev_rank && now_rank ? (prev_rank - now_rank) : nil
  end

  def rank_change_abs
    rank_change.to_i == 0 ? '- -' : rank_change.abs
  end

  def champion?
    1 == now_rank
  end

  # 斩仓：players已有状态，待处理
  def set_liquidation
    update(status: STATUS[:liquidated])
  end

  # 如果用户参加了比赛，其在大赛中的位置
  def self.virtual_rank(contest_id, ret)
    by_contest(contest_id).where("ret <= ?", ret).order(ret: :desc).limit(1).first.try(:now_rank)
  end

  def self.avg_ret(contest_id)
    rets = by_contest(contest_id).select(:ret).map(&:ret)
    return 0 if rets.size.zero?
    rets.map(&:to_f).sum / rets.size
  end

  def self.search(contest_id, page = 1, per_page = 20)
    by_contest(contest_id).ret_desc.includes(:user).paginate(page: page, per_page: per_page)
  end

end
