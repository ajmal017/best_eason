class TradingAccount < ActiveRecord::Base
  include PrettyIdable
  include Feedable

  # 通信密码
  attr_accessor :safety_info

  belongs_to :broker

  belongs_to :user

  belongs_to :parent, class_name: 'TradingAccount'

  has_many :account_values, dependent: :destroy

  has_many :portfolios, foreign_key: "trading_account_id"

  has_many :positions, foreign_key: "trading_account_id"

  has_one :reconcile_request_list

  has_many :orders, foreign_key: "trading_account_id"
  has_many :order_details

  has_many :stock_orders, -> { where(product_type: "stock") }, class_name: "Order", foreign_key: "trading_account_id" do
    def sell; where(type: "OrderSell"); end
    def buy;  where(type: "OrderBuy");  end
  end

  validates_presence_of :broker_no, :broker_id, :user_id

  validates :user, presence: true
  validates :broker_no, :uniqueness => { :scope => [:broker_id], conditions: -> { where(status: STATUS[:normal]) } }#, if: "self.active? || self.audited?" }

  scope :audited, -> { where(status: STATUS[:audited]) }
  scope :binded, -> { where(status: STATUS[:normal]) }
  scope :tradable, ->{ where(status: [STATUS[:normal], STATUS[:recert]]) } # 股票交易时，需要重新认证的也显示
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  # include_simulated 是否包含模拟账户，测试阶段暂时打开模拟账号
  scope :published, ->(include_simulated = false) { where(broker_id: Broker.published(include_simulated).pluck(:id)) }
  scope :sim, -> { where(type: "TradingAccountSim") }
  scope :p2p, -> { where(type: "TradingAccountP2p") }
  scope :sort_by_login, -> { order("last_login_at desc, trading_accounts.id desc") }
  scope :by_markets, ->(*markets) { joins(:broker).where(markets.map{|| 'brokers.market like ?' }.join(' or '), *markets.map{|m| "%#{m}%" }) }
  # 先真实后模拟-先A股后美股
  scope :sort_by_app, -> { joins(:broker).order("FIELD(type, 'TradingAccountPassword', 'TradingAccountSim')").order("FIELD(brokers.market, 'cn', 'hk,us')").order(id: :desc).group(:broker_no) }

  delegate :need_communication_password?, :market_cn?, to: :broker

  STATUS = {
    # 新建
    new: 0,
    # 可以交易
    normal: 1,
    # 审核通过
    audited: 2,
    # 审核未通过
    unaudited: 3,
    # 重新认证
    recert: 9
  }

  STATUS_DESC = {
    0 => "正在审核",
    1 => "绑定成功",
    2 => "审核通过",
    3 => "审核未通过",
    9 => "重新认证"
  }

  scope :active, -> { where(status: STATUS[:normal]) }
  scope :auditing, -> { where(status: STATUS.values_at(:new, :audited, :unaudited)) }
  scope :created_at_gte, -> (date_str) { date_str.present? ? where("trading_accounts.created_at >= ?", Date.parse(date_str)) : all}
  scope :created_at_lte, -> (date_str) { date_str.present? ? where("trading_accounts.created_at <= ?", Date.parse(date_str) + 1) : all}

  def cancelable?
    true
  end

  def active?
    self.status == STATUS[:normal]
  end

  def auditing?
    self.status == STATUS[:new]
  end

  def audited?
    self.status == STATUS[:audited]
  end

  def unaudited?
    self.status == STATUS[:unaudited]
  end

  # 重新认证
  def recert?
    self.status == STATUS[:recert]
  end

  # 是否模拟账号
  def analog?
    false
  end

  def order_types_by(stock)
    #analog? ? stock.order_types.except("0", "limit") : stock.order_types
    stock.order_types
  end

  def status_name
    STATUS_DESC[self.status]
  end

  def broker_name
    broker.cname
  end

  def broker_info
    [broker.cname, broker_no].join(" - ")
  end

  def audited_date
    read_attribute(:audited_date).try(:strftime, "%Y/%m/%d")
  end

  def actived_date
    read_attribute(:actived_date).try(:strftime, "%Y/%m/%d")
  end

  # 绑定
  # TradingAccount.bind(1, ib, {email: "xxx@caishuo.com"})
  def self.bind(user, broker, attrs={})
    broker.bind(user, attrs.symbolize_keys)
  end

  def self.find_with_pretty_id(user_id, pretty_id)
    return nil if user_id.nil?

    account = self.find_by_pretty_id(pretty_id).try(:first)
    account.try(:user_id) == user_id ? account : nil
  end

  # 解绑
  def self.unbind(user, account_pretty_id)
    account = find_with_pretty_id(user.id, account_pretty_id)
    # 如果是a股账号,异步删除相关数据
    if account.is_a?(TradingAccountPassword)
      Resque.enqueue(UnbindTradingAccount, account.id)
    end
    account.destroy if account
  end

  # include_simulated 是否包含模拟账户，默认不包含，测试模拟交易阶段暂时置为true
  # include_recerted 包含实效账户，股票交易时要显示含失效账户，会提示继续绑定
  def self.accounts_by(user_id, market = nil, include_simulated = false, include_recerted = false)
    return [] if user_id.blank?
    accounts = include_recerted ? self.tradable : self.binded
    accounts = accounts.where(user_id: user_id).joins(:broker).includes(:broker)
    accounts = accounts.where("brokers.market like ?", "%#{market}%") if market.present?
    accounts.published(include_simulated).sort_by_login
  end

  # 现金结余(港股美股现金余额有三种，现在统一为base即单位为trading account的base currency)
  def total_cash
    @account_value ||= account_values.of_cash_balance.first
    cash(@account_value)
  end

  # 新版现金额
  def full_cash
    return total_cash unless self.is_a?(TradingAccountPassword)
    
    usable_cash + frozen_cash
  end

  # 可用现金
  def usable_cash
    @usable_cash_account_value ||= account_values.last_total_cash.first
    cash(@usable_cash_account_value)
  end

  def cash(account_value)
    account_value.currency == "BASE" ? account_value.value : account_value.value * Currency.transform(account_value.currency, self.base_currency)
  rescue
    0
  end

  # 冻结资金
  #  暂时A股（password）使用此，如果扩展到broker交易多市场，需要进一步处理
  def frozen_cash
    exchange = Exchange::Base.by_area(broker.market)
    date = ClosedDay.get_work_day(exchange.today-1, broker.market)
    time = Time.parse("#{date.to_s(:db)} #{exchange.close_time}:59")
    OrderDetail.buyed.unfinished.where(trading_account_id: id)
      .joins(:order).where("orders.status <> 'unconfirmed'")
      .where(["order_details.trade_time > ?", time]).sum("order_details.est_cost - if(ISNULL(order_details.real_cost),0,order_details.real_cost)")
  end

  # 美元现金
  def cash_of_usd
    @usd_cash ||= account_values.last_total_cash.currency_with(:USD).first.try(:value).to_f
  end

  # 港币现金
  def cash_of_hkd
    @hkd_cash ||= account_values.last_total_cash.currency_with(:HKD).first.try(:value).to_f
  end

  def total_cash_with_currency(currency)
    cash_with_currency(total_cash, currency)
  end

  def usable_cash_with_currency(currency)
    cash_with_currency(usable_cash, currency)
  end

  def cash_with_currency(cash, currency)
    raise 'trading account base currency cannot be blank!!!' if base_currency.blank?

    cash * Currency.transform(base_currency, currency)
  end

  def usable_cash_of_usd
    usable_cash_with_currency("USD")
  end

  # 证券市值
  def market_value
    @market_value ||= Position.market_value_with(user_id, self)
  end

  # 组合证券市值
  def basket_market_value
    Position.market_value_with(user_id, self, 'basket')
  end

  # 个股证券市值
  def stock_market_value
    Position.market_value_with(user_id, self, 'stock')
  end

  def stock_market_value_of(stock_id)
    Position.market_value_with(user_id, self, 'stock', stock_id)
  end

  def total_property
    @total_property ||= (full_cash + market_value)
  end

  # 仓位比
  def position_percent
    return 0 if total_property <= 0
    (market_value*100/total_property).round(1) rescue 0
  end

  # 持仓股票总的成本
  def costs
    @total_costs ||=  Position.total_costs(self)
  end

  # 货币单位
  def cash_unit
    case base_currency.try(:upcase)
    when 'HKD'
      'HK$'
    when 'USD'
      '$'
    else
      '￥'
    end
  end

  def base_currency_zh
    case base_currency.try(:upcase)
    when 'HKD'
      '港币'
    when 'USD'
      '美元'
    else
      '人民币'
    end
  end

  # 投资概览trading pnl计算使用
  def profit_trade_times
    return [Exchange::Hk.instance.profit_time_range, Exchange::Us.instance.profit_time_range] if self.is_a?(TradingAccountEmail)

    [ Exchange::Cn.instance.profit_time_range ]
  end

  def exec_profit_time_range
    if self.is_a?(TradingAccountEmail)
      [
        {start: Exchange::Hk.instance.exec_start_trade_time, end: Exchange::Hk.instance.exec_end_trade_time},
        {start: Exchange::Us.instance.exec_start_trade_time, end: Exchange::Us.instance.exec_end_trade_time}
      ]
    else
      [ Exchange::Cn.instance.exec_profit_time_range ]
    end
  end

  def cutoff_holding_date
    Time.now.hour >= 9 ? Date.yesterday : 2.days.ago.to_date
  end

  # 个股可买数量，不包含组合中的
  def can_selled_shares_of(stock_id)
    positions = Position.stock_positions_by(stock_id, user_id, id)
    positions.inject(0) { |sum, pos| sum + pos.can_selled_shares }
  end

  def today_profit
    @today_profit ||= today_profit_and_percent[0]
  end

  # 和下面的使用场景有差别
  def today_profit_and_percent
    @today_profit_and_percent ||= PositionArchive.today_profit(self)
  end

  # 总价值的百分比，和account概览页不一样
  def today_total_profit_percent
    cost = total_property - today_profit
    return 0 if cost <= 0
    (today_profit*100/cost).round(2) rescue 0
  end

  def total_profit
    # PositionArchive.total_profit(self, today_profit)   #实际盈亏
    positions.map(&:total_change).sum || 0        #浮动盈亏，当前持仓
  end

  def real_total_profit
    @real_total_profit ||= PositionArchive.total_profit(self, today_profit)
  end

  # 账户的资产、盈亏信息
  def profits
    as_json(
      only: [], methods: [:cash_unit, :total_property, :today_profit, :total_profit, :usable_cash]
    ).merge(id: pretty_id).symbolize_keys
  end

  def stocks_infos
    Position.buyed_stocks_infos(user_id, self)
  end

  # stock_infos, total_entries
  def stocks_infos_by_page(page)
    Position.buyed_stocks_infos(user_id, self, page)
  end

  def baskets_infos
    Position.buyed_baskets_infos(user_id, self)
  end

  def unllocate_positions
    Position.unallocated_by(user_id, id)
  end

  # 持仓的stock或basket占其帐号仓位的比例
  def stock_position
    @stock_position ||= begin
      currency = Currency::Base.new(self.base_currency)

      amount = Position.where(trading_account_id: self.id).inject(0) do |sum, p|
        sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
      end.round(2)

      amount = amount + self.total_cash

      Position.where(trading_account_id: self.id, instance_id: 'others').map do |p|
        {
          id: p.base_stock_id,
          position: (p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency) / amount * 100)
        }
      end
    end
  end

  def basket_position
    @basket_position ||= begin
      currency = Currency::Base.new(self.base_currency)

      amount = Position.where(trading_account_id: self.id).inject(0) do |sum, p|
        sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
      end.round(2)

      amount = amount + self.total_cash

      Position.where(trading_account_id: self.id).where("instance_id != 'others'").group_by(&:instance_id).map do |k,v|
        result = {id: k.to_i}
        result[:position] = (v.sum do |p|
          p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
        end / amount * 100).to_i
        result
      end
    end
  end

  # 持仓比例
  def position_rate
    market_value.zero? ? 0 : market_value.fdiv(total_property) * 100
  end

  def reconcile_by_symbol_and_price(symbol, avg_price)
    portfolio = Portfolio.account_with(id).joins(:base_stock).where("base_stocks.symbol = ? or base_stocks.ib_symbol = ?", symbol, symbol).first
    portfolio.reconcile(avg_price) if portfolio
    exec_details = ExecDetail.where(trading_account_id: id, symbol: symbol, processed: false)
    $pms_logger.info("强制更新ExecDetail: trading_account_id:#{id}, symbol:#{symbol} #{exec_details.pluck(:id).join(',')}") if Setting.pms_logger && exec_details.present?
    exec_details.update_all(processed: true)
    symbols = self.reconcile_request_list.symbol.split(",").delete_if { |x| x == symbol }.join(",")
    self.update!(count: 0) if symbols.blank?
    self.reconcile_request_list.update_attributes(symbol: symbols)
  end

  # 将持仓的组合和股票同步到该用户的自选中
  def sync_follow
    return unless self.user_id.present?

    # 同步关注股票
    positions.by_stock.map(&:base_stock).uniq.each do |stock|
      next if stock.followed_by_user?(self.user_id)

      stock.follow_or_unfollow_by_user(self.user_id)
    end

    # 同步关注组合
    positions.by_basket.map(&:basket).uniq.each do |basket|
      next if basket.followed_by_user?(self.user_id)

      basket.follow_or_unfollow_by_user(self.user_id)
    end
  end

  def set_last_login_at(time = Time.now)
    update(last_login_at: time)
  end

  def login(password, safety_info = nil)
    RestClient.trading.account.login(self, password, safety_info).errors.messages.blank?
  end

  def logined?
    if broker.market_cn?
      last_login_at && last_login_at + 3.hour > Time.now
    else
      true
    end
  end

  def self.sub_account(user_id)
    self.find_by(user_id: user_id).try(:sub_account)
  end
  
  def self.master_account(user_id)
    self.find_by(user_id: user_id).try(:master_account)
  end
  
  def master_account
    self.broker.try(:master_account)
  end
  
  def sub_account
    self.broker_no
  end

  def self.request_execution
    self.all.map(&:request_execution)
  end
  
  def request_execution
    OrderStatusPublisher.publish({"advAccount" => master_account, "subAccount" => sub_account}.to_xml(root: "requestExecutions"))
  end

  # 帐号对应的大盘
  def point_market
    @point_market ||= market_cn? ? BaseStock.sh : BaseStock.nasdq
  end

  # 对比大盘
  def sim_contrast(type="day")
    # 修正日期到交易日当天
    date = ClosedDay.get_work_day(Date.yesterday, point_market.market_area)

    { market_proportion: BaseStock.market_profit(date, point_market), account_proportion: today_total_profit_percent/100 }
  end

  def exec_class
    market_cn? ? ItnExec : TwsExec
  end

  def refresh_cash
    unless $redis.get("trading_account:#{id}:sync_lock")
      $redis.set("trading_account:#{id}:sync_lock", 1, ex: 5)
      (RestClient.trading.cash.sync(id) rescue nil) if market_cn?
    end
  end

  # 胜率
  def win_rate
    Investment.winning_ratio(self).first.try(:round, 2) || 0
  end

  def order_details_by(page = 1, per_page = 8)
    order_details.where("real_shares>0").trade_time_desc.includes(:stock).paginate(page: page, per_page: per_page)
  end

  def valid_orders_count
    orders.traded.count
  end

  # 正在购买中的某股票的价值，排除掉已完成的部分
  def today_buying_value_of(stock_id)
    stock = BaseStock.find(stock_id)
    order_details.submitted.buyed.where("created_at>?", stock.exchange_instance.today).map{|od| od.est_cost}.sum
  end

  def secret_broker_no
    broker_no.first(3).to_s + "***" + broker_no.last(5).to_s
  end
  
  # TODO 下一版更新
  ## 是否存在风险分析
  ## 0:没有持仓 1:已建仓还没有计算出风险分析 2:可以显示风险评估
  #def risk_analysis_usable
    #return 0 unless Position.exists?(trading_account_id: id)
    #AccountPositionRisk.exists?(trading_account_id: id) ? 2 : 1
  #end

  def risk_analysis_usable
    Position.exists?(trading_account_id: id) && AccountPositionRisk.exists?(trading_account_id: id)
  end

  private
end
