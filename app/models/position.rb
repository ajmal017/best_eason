class Position < ActiveRecord::Base
  TYPES = {
    others: "others",
    instance: "instance"
  }

  OPERATOR = {
    order_status: "orderStatus",
    portfolio: "updatePortfolio",
    reconcile: "execDetails"
  }

  belongs_to :order, foreign_key: 'instance_id', primary_key: 'instance_id'
  belongs_to :base_stock
  belongs_to :basket
  belongs_to :user

  belongs_to :trading_account

  validates :instance_id, presence: true
  validates :base_stock_id, presence: true
  # validates :average_cost, numericality: { greater_than_or_equal_to: 0.0 }, allow_blank: true
  validates :pending_shares, numericality: :only_integer, allow_blank: true

  scope :by_basket_and_user, -> (basket_id, user_id) { where(instance_id: basket_id, user_id: user_id) }
  scope :by_ib_id_or_symbol, -> (ib_id, symbol) { where("base_stocks.ib_id = ? or base_stocks.ib_symbol = ?", ib_id, symbol) }
  scope :valid_currency, -> { where.not(currency: nil) }

  scope :by_stocks, -> { includes(:base_stock).where.not(base_stock_id: nil) }
  scope :by_baskets, -> { includes(:basket).where.not(basket_id: nil) }

  # 从某个用户获得
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # 从某个账户获得
  scope :account_with, ->(account_id) { where(trading_account_id: account_id)}

  # 从某个主题获得
  scope :basket_with, ->(basket_id) { where(basket_id: basket_id) }
  scope :instance_with, ->(instance_id) { where(instance_id: instance_id) }

  # 从某只股票获得
  scope :stock_id_with, -> ( stock_id ) { where( base_stock_id: stock_id ) }

  scope :stock_with, -> ( stock_id ) { where( base_stock_id: stock_id ) }

  # 港股投资
  scope :with_sehk, -> { where(base_stocks: {exchange: 'SEHK'}) }
  # 美股投资
  scope :with_us, -> { where(base_stocks: {exchange: ['NASDAQ', 'NYSE']})}

  scope :allocated, -> { where.not(instance_id: "unallocate") }
  scope :unallocated, -> { where(instance_id: "unallocate") }
  # 个股投资
  scope :stock_invest, -> { where(instance_id: "others") }
  # 主题投资
  scope :basket_invest, -> { where.not(instance_id: ["unallocate", "others"]) }

  # unallocate
  scope :unallocate, -> { where(instance_id: "unallocate") }

  scope :allocated, -> { where.not(instance_id: "unallocate") }
  scope :unallocated, -> { where(instance_id: "unallocate") }
  # 投资类型
  scope :invest_by, -> (type_name) { type_name.blank? ? all : (type_name == 'basket' ? where.not(instance_id: ['unallocate', 'others']) : where(instance_id: 'others'))}

  scope :updated_desc, -> { order(updated_at: :desc) }

  delegate :realtime_price, :change_percent, to: :base_stock

  before_create :set_user

  # 总的成本
  def total_cost
    shares.zero? ? (closed_cost || 0) : (average_cost * shares rescue 0)
  end

  def market_value
    realtime_price * shares rescue 0
  end

  def total_change
    shares.zero? ? pnl.to_f : (market_value - total_cost)
  end

  def total_change_percent
    Caishuo::Utils::Helper.div_percent(total_change, total_cost.abs)
  end

  def shares
    read_attribute(:shares).to_i
  end

  def self.stock_position_by_basket_and_user(basket_id, user_id, ib_id, symbol)
    self.by_basket_and_user(basket_id, user_id).joins(:base_stock).by_ib_id_or_symbol(ib_id, symbol).readonly(false).first
  end

  def adjust_pending_shares(selled_shares)
    $pms_logger.info("更新pending_shares: 更新前#{self.pending_shares.to_f}，更新后#{self.pending_shares.to_f - selled_shares.to_f}")
    self.update_attributes(pending_shares: self.pending_shares.to_f - selled_shares.to_f)
  end

  def split(before_split, after_split)
    $pms_logger.info("UpdatePortfolio: 分股,before_split_shares=#{self.shares.to_i},after_split_shares=#{self.shares.to_i * before_split/after_split},before_split_avg=#{self.average_cost},after_split_avg=#{self.average_cost * after_split/before_split},stock_id=#{self.base_stock_id},instance_id=#{self.instance_id},user_id=#{self.user_id}") if Setting.pms_logger
    update_attributes_with_lock(shares: self.shares.to_i * before_split/after_split, average_cost: self.average_cost * after_split/before_split)
  end

  def update_attributes_with_lock(attrs)
    self.with_lock do
      self.attributes = attrs
      self.save!
    end
  end

  def can_selled_shares
    self.shares.to_i - self.pending_shares.to_i - self.buy_frozen.to_i
  end

  def others?
    self.instance_id == "others"
  end

  def filled_gte_shares(filled)
    filled.to_d >= current_shares
  end

  def current_shares
    self.shares.present? ? self.shares : 0
  end

  def current_average_cost
    self.average_cost.present? ? self.average_cost : 0
  end

  def copy_attrs(options)
    self.update_attributes_with_lock(options)
    self
  end

  def update_shares_and_avg_price(side, this_time_filled, this_time_cost)
    $pms_logger.info("OrderStatus: 更新前持仓#{shares},#{average_cost}") if Setting.pms_logger

    self.update_attributes_with_lock(average_cost: compute_average_cost(this_time_filled, this_time_cost, side), shares: compute_shares(side, this_time_filled))

    $pms_logger.info("OrderStatus: 更新后持仓#{shares},#{average_cost}") if Setting.pms_logger
  end

  def compute_shares(side, this_time_filled)
    side == "BOT" ? current_shares + this_time_filled : current_shares - this_time_filled
  end

  def compute_average_cost(this_time_filled, this_time_cost, side)
    return 0 if (current_shares + this_time_filled).to_i == 0
    if side == "BOT"
      if current_shares >= 0
        (current_average_cost * current_shares + this_time_cost)/(current_shares + this_time_filled)
      else
        current_shares.abs > this_time_filled ? current_average_cost : this_time_cost/this_time_filled
      end
    else
      if current_shares >= 0
        current_shares.abs > this_time_filled ? current_average_cost : this_time_cost/this_time_filled
      else
        (current_average_cost * current_shares + this_time_cost)/(current_shares + this_time_filled)
      end
    end
  end

  def update_others_shares(shares)
    self.update_attributes_with_lock(shares: shares.to_i)
  end

  def update_others_position(shares, avg_cost)
    self.update_attributes_with_lock(shares: shares.to_i, average_cost: avg_cost.to_d, updated_by: Position::OPERATOR[:portfolio])
  end

  def update_avg_cost(avg_cost)
    self.update_attributes_with_lock(average_cost: avg_cost.to_d)
  end

  def reconcile(attrs)
    $pms_logger.info("ExecDetails Api: 调平前持仓 #{shares},#{average_cost},#{pending_shares}")  if Setting.pms_logger
    update_attributes_with_lock(attrs)
    $pms_logger.info("ExecDetails Api: 调平后持仓 #{shares},#{average_cost},#{pending_shares}")  if Setting.pms_logger
  end

  def tws_reconcile!(shares, avg_price, side)
    $pms_logger.info("ExecDetails Tws: 调平前持仓#{shares},#{average_cost}") if Setting.pms_logger

    self.update_attributes_with_lock(average_cost: compute_average_cost(shares, shares * avg_price, side), shares: compute_shares(side, shares))

    $pms_logger.info("ExecDetails Tws: 调平后持仓#{shares},#{average_cost}") if Setting.pms_logger

    adjust_position(avg_price) if current_shares < 0
  end

  def adjust_position(avg_price)
    $pms_logger.info("ExecDetails Tws: 调平后股数为负，调整") if Setting.pms_logger
    portfolio.adjust_position(avg_price)
  end

  def tws_reconciled_attrs(tws_shares)
    { average_cost: others_avg_cost(tws_shares), shares:  self.shares.to_i + tws_shares.to_i }
  end

  def others_avg_cost(tws_shares)
    self.shares.to_i + tws_shares.to_i == 0 ? 0 : others_total_cost/(self.shares.to_i + tws_shares.to_i)
  end

  def others_total_cost
    portfolio_total_cost - basket_total_cost
  end

  def portfolio_total_cost
    portfolio.position.to_i * portfolio.average_cost
  end

  def basket_total_cost
    self.user.basket_positions.stock_id_with(self.base_stock_id).inject(0) { |sum, p|  sum += p.shares.to_i * p.average_cost.to_d}
  end

  def portfolio
    @portfolio ||= Portfolio.account_with(trading_account_id).stock_with(self.base_stock_id).first
  end


  #########################投资概览页面相关计算######################

  # 主题投资(basket)/个股投资(stock)/用户证券(nil)市值
  # 为了和证券市值计算出来的价值一样(证券市值=主题市值+个股市值),此处股票价格采用实时价格
  # 计算方法: 所有持仓的主题/个股的股票(实时价格*持仓数*汇率),做空属于负资产,不采用绝对值计算
  # 用户证券市值同样采用此方法
  def self.market_value_with(user_id, account, type_name = nil, stock_id = nil)
    positions = account_with(account.id).invest_by(type_name).valid_currency
    positions = positions.stock_with(stock_id) if stock_id.present?

    positions.inject(0) do |sum, p|
      rate = Currency::Cache.transform(p.currency, account.base_currency)
      sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * rate
    end.round(2)
  end

  # 持仓总成本
  def self.total_costs(account)
    currency = Currency::Base.new(account.base_currency)

    account_with(account.id).valid_currency.inject(0) do |sum, p|
      sum + p.shares * p.average_cost * currency.rate(p.currency)
    end.round(2)
  end

  def self.total_property_for(account_id)
    account = TradingAccount.find(account_id)
    account.total_cash + market_value_with(account.user_id, account)
  end

  # 主题投资/个股投资比例
  def self.invest_ratio(user)
    %w(cash basket stock).map{ |type_name| [type_name.to_sym, send("#{type_name}_invest_percent", user)]}.to_h
  end

  def self.invest_pie_charts(user)
    [user.total_cash.to_f, user.basket_market_value.to_f, user.stock_market_value.to_f, user.cash_unit]
  end

  def self.cash_invest_percent(user)
    [user.total_cash, div_percent(user.total_cash, user.total_property)]
  end

  def self.basket_invest_percent(user)
    [user.basket_market_value, div_percent(user.basket_market_value, user.total_property)]
  end

  def self.stock_invest_percent(user)
    percent = user.stock_market_value.zero? ? 0 : ( 100 - cash_invest_percent(user)[1] - basket_invest_percent(user)[1] ).round(2)
    [user.stock_market_value, percent]
  end

  def self.div_percent(molecular, denominator)
    Caishuo::Utils::Helper.div_percent(molecular, denominator)
  end

  def self.exchange_rates(base_currency)
    %w(usd hkd).map{ |currency| [currency.to_sym, Currency.transform(currency, base_currency)] }.to_h
  end

  # 主板和创业板市值以及投资比例(美股港股没有主板和创业板取市场投资比例)
  def self.sector_market_value(account)
    return market_proportion_of_investment(account) unless account.broker.market == "cn"

    currency = Currency::Base.new(account.base_currency)

    listed_sectors = {1 => "主板", 6 => "创业板"}

    stock_values = account_with(account.id).valid_currency.group_by(&:base_stock_id).map do |base_stock_id, ps|
      [base_stock_id, ps.sum{|p| p.shares * currency.rate(p.currency) * ::Rs::Stock.new(p.base_stock_id).realtime_price}]
    end.to_h

    sectors = BaseStock.where(id: stock_values.map(&:first), listed_sector: listed_sectors.keys).group_by(&:listed_sector).map do |listed_sector, bs|
      [listed_sector, stock_values.slice(*bs.map(&:id)).values.sum]
    end.to_h

    listed_sectors.map do |sector, name|
      {amount: sectors[sector].to_f.round(2), percent: div_percent(sectors[sector].to_f, sectors.values.sum.to_f), name: name}
    end
  end

  # 美股港股投资比例
  def self.market_proportion_of_investment(account)
    currency = Currency::Base.new(account.base_currency)

    markets = {:us => "美股", :hk => "港股"}

    sectors = account_with(account.id).valid_currency.group_by(&:market).map do |market, ps|
      [market.to_sym, ps.sum{|p| p.shares * currency.rate(p.currency) * ::Rs::Stock.new(p.base_stock_id).realtime_price}]
    end.to_h

    markets.map do |market, name|
      {amount: sectors[market].to_f, percent: div_percent(sectors[market].to_f, sectors.values.sum.to_f), name: name}
    end
  end

  # 赚的最多亏的最多的两只股票
  def self.max_profit_and_loss(account_id)
    ps = account_with(account_id).stock_invest.where("average_cost > 0").map do |p|
      percent = (::Rs::Stock.new(p.base_stock_id).realtime_price - p.average_cost).fdiv(p.average_cost) * 100
      [(percent >= 0 ? "profit" : "loss"), {base_stock_id: p.base_stock_id, percent: percent.to_f}]
    end.minmax_by{|x| x.last[:percent]}.compact

    ps.map{|k, v| [k, v.merge(cname: BaseStock.find(v[:base_stock_id]).c_name)]}.to_h.reverse_merge("profit" => nil, "loss" => nil)
  end

  # 用户持仓比例
  def self.user_percent_position(user_id)
    market_value = user_market_value(user_id)
    return 0 if market_value.zero?

    market_value.fdiv(market_value + AccountValue.total_cash(user_id)) * 100
  end

  # 某只股票持仓比例
  def self.stock_percent_position(user_id, stock_id)
    currency = Currency::Base.new('USD')

    stock_market_value = Position.where(trading_account_id: TradingAccount.binded.by_user(user_id).pluck(:id), base_stock_id: stock_id).valid_currency.inject(0) do |sum, p|
      sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
    end.round(2)

    return 0 if stock_market_value.zero?

    stock_market_value.fdiv(user_market_value(user_id)) * 100
  end

  def self.user_market_value(user_id)
    currency = Currency::Base.new('USD')
    Position.where(trading_account_id: TradingAccount.binded.by_user(user_id).pluck(:id)).valid_currency.inject(0) do |sum, p|
      sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
    end.round(2)
  end

  # 换手率， 三十天的买入，卖出的总额/当时的账户净值
  def self.turnover_rate(account)
    currency = Currency::Base.new(account.base_currency)

    trading_cost = OrderDetail.account_with(account.id).where("trade_time >= ?", 30.days.ago).profited.inject(0) do |sum, od|
      sum + od.real_cost.to_f * currency.rate(od.currency)
    end

    result = account.total_property.zero? ? 0 : trading_cost.fdiv(account.total_property) * 100

    {turnover_rate: result, average_rate: Investment.average_turnover_rate}
  end

  # 一月回报: 计算公式（总盈亏 / 当前净值 x 100%)
  def self.one_month_average_return
    Investment.one_month_return
  end

  # 一月回报: 计算公式（总盈亏 / 当前净值 x 100%),结果是乘以了100
  def self.one_month_return(account)
    start_pnl, yesterday_pnl = UserProfit.select("trading_account_id, total_pnl, date").where(trading_account_id: account.id, date: 30.days.ago..1.days.ago).minmax_by{|x|x.date}.compact.map{|x|x.total_pnl * Currency.transform('USD', account.base_currency)}
    rate = (yesterday_pnl.to_f + account.today_profit - start_pnl.to_f).fdiv(account.total_property) * 100

    {one_month_return_rate: rate.round(2), average_one_month_return_rate: one_month_average_return(account).round(2)}
  end

  # 用户平均一月回报
  def self.one_month_average_return(account)
    Investment.one_month_return(account.type)
  end

  # 三十天平均仓位: 计算公式（股票净值/总净值，每天取，然后平均）
  def self.one_month_average_position(account)
    positions = UserDayProperty.where(trading_account_id: account.id).where(date: 30.days.ago..1.days.ago).inject([]) do |ret, property|
      ret.push (property.total - property.total_cash).fdiv(property.total) * 100
    end

    {position_rate: positions.push(account.position_rate).average, average_position_rate: Investment.one_month_user_average_position}
  end

  # 手机端累计盈亏以及百分比
  def self.total_profit_and_loss(account)
    return account.profit_and_percent_by("total") if account.analog?
    profit = account.total_profit
    [profit, (account.costs.zero? ? 0 : profit.fdiv(account.costs) * 100)]
  end

  #--------------   持仓明细计算  ------------------

  def self.basket_positions_of_latest_updated(trading_account_id)
    Position.account_with(trading_account_id).basket_invest.where("shares <> 0")
            .select(:id, :instance_id, :basket_id, :updated_at).includes(:basket)
            .group_by{|p| p.instance_id}
            .map{|_, positions| positions.sort_by{|x| x.updated_at}.last }
  end

  # 批量组合
  def self.buyed_baskets_infos(user_id, account)
    positions = basket_positions_of_latest_updated(account.id)
    instance_ids = positions.map(&:instance_id)
    baskets_profits = PositionArchive.bubble_basket_profit(account, instance_ids)
    grouped_positions = grouped_positions_by(user_id, account.id, instance_ids)
    basket_position = account.basket_position

    positions.map do |p|
      infos = positions_change_infos(grouped_positions[p.instance_id], baskets_profits[p.instance_id])
      infos.merge!(p.basket.newest_version.infos_for_position)
      infos.merge!(single_position: basket_position.find{|ps| ps[:id].to_i == p.basket.original_id }.try(:fetch, :position).to_f)
      infos.merge!(realtime_index: p.basket.newest_version.try(:realtime_index).try(:to_f))
      [infos, p.updated_at]
    end.sort_by{|x| x[1]}.reverse.map{|x| x[0]}
  end

  # 调整页调用单个组合
  def self.basket_infos(instance_id, user_id, account)
    positions = instance_with(instance_id).account_with(account.id).includes(:base_stock)
    profits = PositionArchive.today_basket_profit(account, instance_id)
    positions_change_infos(positions, profits)
  end

  def self.grouped_positions_by(user_id, account_id, instance_ids)
    by_user(user_id).account_with(account_id).where(instance_id: instance_ids)
                    .includes(:base_stock).group_by{|p| p.instance_id}
  end

  def self.positions_change_infos(positions, today_profits)
    total_cost = total_cost(positions)
    market_value = market_value(positions)
    total_changes = total_changes(positions)
    percentage = Caishuo::Utils::Helper.div_percent(total_changes, total_cost)
    {
      total_change: total_changes, total_change_percent: percentage,
      total_cost: total_cost, total_value: market_value,
      today_change: today_profits.first, today_change_percent: today_profits.last
    }
  end

  def self.total_cost(positions)
    positions.map(&:total_cost).sum || 0
  end

  def self.market_value(positions)
    positions.map(&:market_value).sum || 0
  end

  def self.total_changes(positions)
    positions.map(&:total_change).sum || 0
  end

  # 某个组合持仓中的持仓明细的数据
  def self.basket_stocks_infos(user_id, instance_id, trading_account)
    positions = instance_with(instance_id).account_with(trading_account.id)
    position_stocks_infos(positions, user_id, trading_account, instance_id)
  end

  # 一次性获取 个股持仓明细中使用的数据
  # page 为nil时，不分页取全部(app端使用)，否则按10条分页(网页端使用)
  def self.buyed_stocks_infos(user_id, account, page = nil)
    positions = buyed_stocks(user_id, account.id).order(id: :asc)
    positions = positions.paginate(page: page, per_page: 10) if page
    infos = position_stocks_infos(positions, user_id, account)
    if page
      return infos, positions.total_entries
    else
      infos
    end
  end

  def self.buyed_stocks(user_id, trading_account_id)
    by_user(user_id).account_with(trading_account_id).stock_invest
  end

  def self.position_stocks_infos(positions, user_id, account, instance_id = nil)
    positions = positions.includes(base_stock: [:stock_screener])
    stocks_profits = stocks_today_change(positions, user_id, account, instance_id)
    stock_position = account.stock_position

    ods = OrderDetail.select("base_stock_id, trade_type, max(updated_at)").where(trading_account_id: account).fill_finished.group(:base_stock_id).pluck(:base_stock_id, :trade_type)
    type_list = {"OrderSell" => 4, "OrderBuy" => 3}

    positions.map do |position|
      infos = position.profit_infos
      base_stock = position.base_stock
      today_changes = stocks_profits[position.base_stock_id]
      infos.merge!(today_change: today_changes.first, today_change_percent: today_changes.last)
      infos.merge!(screenshot: base_stock.screenshot)
      infos.merge!(listed_state: base_stock.try(:listed_state) || 1)
      infos.merge!(market_status: base_stock.market_status)
      infos.merge!(previous_close: base_stock.previous_close)
      infos.merge!(single_position: stock_position.find{|ps| ps[:id] == position.base_stock_id }.try(:fetch, :position).to_f)
      infos.merge!(average_cost: position.average_cost)
      infos.merge!(realtime_price: base_stock.realtime_price)
      infos.merge!(can_selled_shares: position.can_selled_shares)
      infos.merge!(up_price: (base_stock.up_price.to_f rescue 0), down_price: (base_stock.down_price.to_f rescue 0))
      infos.merge!(action: (type_list[ods.find{|o| o.first == base_stock.id}.last] rescue nil))
    end
  end

  def profit_infos
    {
        total_change: total_change, total_change_percent: total_change_percent,
        total_count: shares, available_count: can_selled_shares, total_cost: total_cost.round(2), realtime_price: realtime_price,
        stock_change_percent: change_percent,
        total_value: market_value, stock_score: base_stock.stock_screener.try(:score)
    }.merge(base_stock.infos_for_positions)
  end

  def self.stocks_today_change(positions, user_id, account, instance_id = nil)
    if instance_id
      basket_stocks_today_change(positions, user_id, account, instance_id)
    else
      PositionArchive.bubble_stock_profit(account, positions.map(&:base_stock_id))
    end
  end

  def self.basket_stocks_today_change(positions, user_id, account, instance_id)
    changes_map = {}
    positions.map(&:base_stock_id).each do |stock_id|
      profits = PositionArchive.today_basket_profit(account, instance_id, stock_id)
      changes_map[stock_id] = profits
    end
    changes_map
  end

  # app 通过股票查所有账户收益相关数据 todo:1 盈亏计算
  #  TODO 计算的pnl数据有问题
  def self.stock_profits(stock_id, user_id, account = nil)
    account_ids = account ? [account.id] : User.find_by_id(user_id).try(:active_account_ids)
    positions = by_user(user_id).stock_id_with(stock_id).account_with(account_ids).includes(:base_stock)

    shares = positions.map(&:shares).sum.to_i
    total_cost = total_cost(positions)
    market_value = market_value(positions)
    avg_cost = shares.zero? ? 0 : total_cost/shares

    current_change = market_value - total_cost
    current_change_percent = Caishuo::Utils::Helper.div_percent(current_change, total_cost.abs)
    archived_profit, all_cost = UserStockProfit.archived_profit_and_cost(stock_id, user_id, account_ids)
    total_change = archived_profit + current_change
    total_change_percent = Caishuo::Utils::Helper.div_percent(total_change, all_cost.abs)

    {
      shares: shares, avg_cost: avg_cost, market_value: market_value, total_cost: total_cost,
      current_change: current_change, current_change_percent: current_change_percent,
      total_change: total_change, total_change_percent: total_change_percent
    }
  end

  # 收益Json输出
  def profit_json
    # 1310.0, 4.77
    current_change, current_change_percent = PositionArchive.today_stock_profit(trading_account, base_stock_id)
    {
      broker_name: trading_account.broker.cname, broker_no: trading_account.broker_no, account_id: trading_account.pretty_id,
      shares: shares, avg_cost: average_cost, market_value: market_value, total_cost: total_cost,
      current_change: current_change, current_change_percent: current_change_percent,
      total_change: total_change, total_change_percent: total_change_percent
    }
  end

  # 根据持仓来查找所有交易账号下的股票收益
  def self.stock_profits_in_position(stock_id, user_id, account = nil)
    stock = BaseStock.find_by(id: stock_id)
    user = User.find_by_id(user_id)
    return [] if stock.blank? or user.blank?

    account_ids = account ? [account.id] : user.active_account_ids
    positions = by_user(user_id).stock_id_with(stock_id).account_with(account_ids).where(["shares > ?", 0]).includes(:base_stock, :trading_account)
    positions.map(&:profit_json)
  end

  def self.stock_profits_total(stock_id, user_id)
    data = stock_profits_in_position(stock_id, user_id)
    return [] if data.blank?
    
    shares = data.sum{|p| p[:shares] || 0 } || 0
    total_cost = data.sum{|p| p[:total_cost] || 0 } || 0
    market_value = data.sum{|p| p[:market_value] || 0 } || 0
    current_change = data.sum{|p| p[:current_change] || 0 } || 0
    current_change_percent = Caishuo::Utils::Helper.div_percent(current_change, total_cost.abs) || 0
    avg_cost = shares.zero? ? 0 : total_cost/shares

    total_change = market_value - total_cost
    total_change_percent = Caishuo::Utils::Helper.div_percent(total_change, total_cost.abs)

    data << {
      broker_name: "all", broker_no: "all", account_id: "",
      shares: shares, avg_cost: avg_cost, market_value: market_value, total_cost: total_cost,
      current_change: current_change, current_change_percent: current_change_percent,
      total_change: total_change, total_change_percent: total_change_percent
    }

  end


  # ===============others为负值时调整到对应的basket上======================

  def can_sub(sum = nil)
    shares.to_f >= subtracted_shares(sum) ? subtracted_shares(sum) : shares.to_f
  end

  def subtracted_shares(sum = nil)
    @sub_shares || ( @sub_shares = sum.present? ? others_shares.abs - sum : (unstructured_subtracted / board_lot).round * board_lot )
  end

  def unstructured_subtracted
    basket_total_shares.to_i == 0 ? 0 : (self.shares.to_f/basket_total_shares) * others_shares.abs
  end

  def board_lot
    @lot || ( @lot = base_stock.get_board_lot )
  end

  def basket_total_shares
    @total_shares || ( @total_shares = basket_positions.inject(0) { |sum, pos| sum + pos.shares.to_i } )
  end

  def basket_positions
    user.basket_positions.stock_id_with(base_stock_id)
  end

  def others_shares
    others_position.shares.to_i
  end

  def others_position
    Position.find_or_create_by(instance_id: "others", base_stock_id: base_stock_id, trading_account_id: trading_account.id)
  end

  def distribute_from_others(sub)
    self.update_attributes(shares: self.shares.to_f - sub, updated_by: OPERATOR[:portfolio])
  end

  def distribute_and_create_order(sum = nil, avg_price)
    at_most_sub = can_sub(sum) #临时变量必须，can_sub不是幂等的
    distribute_from_others(at_most_sub)
    create_order(at_most_sub, avg_price) if avg_price && at_most_sub > 0
    at_most_sub
  end

  def create_order(shares, avg_price)
    order_details_attributes = { "0" => {
      trade_time: Time.now,
      est_shares: shares,
      real_shares: shares,
      status: "filled",
      base_stock_id: base_stock_id,
      trade_type: "OrderSell",
      real_cost: shares * avg_price
      }
    }
    attrs = {
      background: true,
      real_cost: shares * avg_price,
      status: "completed",
      order_details_complete_count: 1,
      user_id: user_id,
      basket_mount: 1,
      basket_id: create_basket.id,
      order_details_attributes: order_details_attributes
    }
    OrderSell.create!(attrs)
  end

  def create_basket
    basket_stocks_attributes = {
      basket_stocks_attributes: { "0" => {
        weight: 1,
        stock_id: self.base_stock_id
        }
      }
    }
    custom_from_basket = Basket.find(self.basket_id)
    Basket::Custom.create_from(self.user_id, custom_from_basket, basket_stocks_attributes)
  end

  def self.basket_positions_by(instance_id, user_id, account_id)
    Position.basket_invest.instance_with(instance_id).account_with(account_id).by_user(user_id).where("shares <> 0")
  end

  def self.stock_positions_by(stock_id, user_id, account_id)
    Position.stock_invest.stock_id_with(stock_id).by_user(user_id).account_with(account_id)
  end

  # updatePortfolio 代理方法

  def others_shares_zero?
    self.shares.to_i == 0
  end

  def initial_shares
    self.shares.to_i
  end

  def initial_pending_shares
    self.pending_shares.to_i
  end

  def position_previous_cost
    self.shares.to_f * self.average_cost.to_f
  end

  before_save :set_market_and_currency, if: "self.market.blank? || self.currency.blank?"
  def set_market_and_currency
    self.market = base_stock.try(:market_area)
    self.currency = base_stock.try(:currency)
  end

  def self.unallocated_by(user_id, trading_account_id)
    by_user(user_id).account_with(trading_account_id).unallocate.includes(:base_stock)
  end

  private
  # def self.one_position_by(user_id, instance_id)
  #   self.instance_with(instance_id.to_s).by_user(user_id).order("updated_at desc").first
  # end

  def set_user
    self.user_id = self.trading_account.user_id
  end
end
