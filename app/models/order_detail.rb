class OrderDetail < ActiveRecord::Base
  STATUS = {
    ready: "交易中",
    submitted: "已报",
    filled:  "成交",
    partial_filled: '部分完成',
    cancelled: "取消",
    expired: "失效", # 过期
    error: '出错',
    inactive: '无效',
    rejected: '无法下单',
    api_cancelled: '无法下单',
    cancelling: '已报待撤'
  }

  belongs_to :user
  belongs_to :order
  belongs_to :stock, class_name: 'BaseStock', foreign_key: 'base_stock_id'

  validates :instance_id, presence: true, on: :update
  validates :trading_account_id, presence: true, on: :update
  validates :base_stock_id, presence: true
  validates :symbol, presence: true
  validates :user_id, presence: true, on: :update
  validates :order_id, presence: true, on: :update
  validates :real_cost, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :est_shares, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :est_cost, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :real_shares, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  scope :by_basket_and_user, -> (basket_id, user_id) { where(instance_id: basket_id, user_id: user_id) }
  scope :by_order, ->(order_id) { where(order_id: order_id) }
  scope :by_ib_id_or_symbol, ->(ib_id, symbol) { where("base_stocks.ib_id = ? or base_stocks.ib_symbol = ?", ib_id, symbol) }
  scope :has_filled, -> { where(:status => :filled) }
  scope :executing, -> { where(status: ['ready', 'submitted']) }
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :profited, -> { where(status: ['submitted', 'filled', 'cancelled', 'partial_filled'], background: [false, nil]).where.not(currency: nil) }
  scope :trade_time_range, -> (start_time, end_time) { where("trade_time >= ? and trade_time <= ?", start_time, end_time) }
  scope :with_sehk, -> { where(base_stocks: {exchange: 'SEHK'}) }
  scope :with_us, -> { where.not(base_stocks: {exchange: 'SEHK'}) }
  scope :instance_with, -> (instance_id) { where(instance_id: instance_id) unless instance_id.nil? }
  scope :stock_with, ->(stock_id) { where(base_stock_id: stock_id) unless stock_id.nil? }
  scope :category_with, ->(opts) { instance_with(opts[:instance_id]).stock_with(opts[:stock_id])}
  scope :account_with, -> (account_id) { where(trading_account_id: account_id) }
  scope :except_background, -> { where(background: [false, nil]) }
  scope :market_with, ->(market) { where(market: market) }
  scope :valid_currency, -> { where.not(currency: nil) }
  scope :buyed, -> { where(trade_type: 'OrderBuy') }
  scope :selled, -> { where(trade_type: 'OrderSell') }
  scope :trade_time_desc, -> { order(trade_time: :desc) }
  scope :unfinished, -> { where(status: [:ready, :submitted, :cancelling]) }
  scope :submitted, -> { where(status: 'submitted') }
  scope :fill_finished, -> { where(status: ['filled', 'partial_filled']) }

  scope :trade_time_lte, ->(end_time) { where("trade_time <= ?", end_time) }

  delegate :exchange, :ib_symbol, :com_name, to: :stock
  before_create :copy_attrs #, :adjust_shares
  before_validation :set_est_cost, :set_symbol, if: Proc.new {|od| od.new_record?}

  include AASM
  aasm :skip_validation_on_save => true, :column => 'status' do
    state :ready, :initial => true
    state :submitted
    state :partial_filled, :before_enter => [:check_reconciled, :request_portfolio]
    state :filled, :before_enter => [:check_reconciled, :request_portfolio]
    state :cancelled, :before_enter => [:check_reconciled, :request_portfolio]
    state :expired, :before_enter => [:check_reconciled, :request_portfolio]
    state :error, :before_enter => [:check_reconciled, :request_portfolio]
    state :inactive, :before_enter => [:check_reconciled, :request_portfolio]
    state :rejected, :before_enter => [:check_reconciled, :request_portfolio]
    state :api_cancelled, :before_enter => [:check_reconciled, :request_portfolio]

    event :submit do
      transitions :from => [:ready, :submitted], :to => :submitted, :on_transition => Proc.new {|obj, *args| obj.update_cost_and_shares(*args) }
    end

    event :fill do
      transitions :from => [:ready, :submitted], :to => :filled, :on_transition => Proc.new {|obj, *args| obj.update_cost_and_shares(*args) }
    end

    event :cancel do
      transitions :from => [:ready, :submitted], :to => :cancelled, :on_transition => Proc.new {|obj, *args| obj.update_cost_and_shares(*args) }
    end

    event :partial_fill do
      transitions :from => [:ready, :submitted], :to => :partial_filled, :on_transition => Proc.new {|obj, *args| obj.update_cost_and_shares(*args) }
    end

    event :reconcile do
      transitions :from => [:ready, :submitted], :to => :filled, :on_transition => Proc.new {|obj, *args| obj.reconcile_cost_and_shares(*args) }
    end

    event :expire, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :expired
    end

    event :to_error, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :error
    end

    event :adjust, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :error
    end

    event :inactivate, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :inactive
    end

    event :reject, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :rejected
    end

    event :api_cancell, :after => :adjust_order do
      transitions :from => [:ready, :submitted], :to => :api_cancelled
    end

    event :admin_cancell, :after => [:modify_pending_shares] do
      transitions :from => [:ready, :submitted], :to => :cancelled
    end
  end

  def check_reconciled
    self.user.check_reconciled
  end

  def request_portfolio
    Resque.enqueue_at(1.seconds.from_now, PortfolioRequest, self.user.trading_accounts.first.id)
  end

  def adjust_shares
    self.est_shares = can_selled_shares if self.trade_type == "OrderSell"
  end

  def modify_pending_shares
    adjust_pending_shares if self.trade_type == "OrderSell"
    self.update_attributes(updated_by: "admin_cancell")
  end

  def currency_unit
    self.stock.currency_unit
  end

  def adjust_order
    $pms_logger.info("adjust_order: 订单报错，报错前，detail：#{self.real_shares},#{self.real_cost},挂起股数#{position.try(:pending_shares)}")  if Setting.pms_logger
    adjust_pending_shares if self.trade_type == "OrderSell"
    self.order.update_real_cost_and_count(0, 0)
    self.update_attributes(updated_by: "error")
    complete_order!("error") if self.order.order_details_complete_count == self.order.order_details.count
    $pms_logger.info("adjust_order: 订单报错，报错后，detail：#{self.real_shares},#{self.real_cost},挂起股数#{position.try(:pending_shares)}")  if Setting.pms_logger
  end

  def adjust_pending_shares
    position.adjust_pending_shares(self.est_shares.to_f - self.real_shares.to_f) 
  end

  # TODO: basket sell时调整shares
  def can_selled_max_shares
    if self.basket_id.blank?
      self.user.can_selled_shares_of(self.base_stock_id)
    else

    end
  end

  def can_selled_shares
    [can_selled_max_shares, board_lot_est_shares].min
  end

  def board_lot
    stock.board_lot.present? ? stock.board_lot : 1
  end

  def board_lot_est_shares
    self.est_shares%board_lot == 0 ? self.est_shares : (self.est_shares/board_lot + 1) * board_lot
  end

  def position
    @position ||= Position.find_by(instance_id: self.instance_id, trading_account_id: self.trading_account_id, base_stock_id: self.base_stock_id)
  end

  def size
    self.order.is_a?(OrderSell) ? minus_size : est_shares.to_i
  end

  def minus_size
    "-#{est_shares.to_i}"
  end

  def self.stock_detail_by_basket_and_user(instance_id, user_id, ib_id, symbol, order_id)
    self.by_basket_and_user(instance_id, user_id).joins(:stock).where("(base_stocks.ib_id = ? or base_stocks.ib_symbol = ?) and order_details.order_id = ?", ib_id, symbol, order_id).readonly(false).first
  end

  def self.fetch_one_by(ib_id, symbol, order_id)
    self.by_order(order_id).joins(:stock).by_ib_id_or_symbol(ib_id, symbol).readonly(false).first
  end

  def self.fetch_by(ib_symbol, instance_id, order_id)
    OrderDetail.joins(:stock).where("base_stocks.ib_symbol = ? and order_details.instance_id = ? and order_details.order_id = ?", ib_symbol, instance_id, order_id).readonly(false)
  end

  #todo adjust时需要修改trade_type
  def copy_attrs
    self.instance_id = self.order.instance_id
    self.user_id = self.order.user_id
    self.basket_id = self.order.basket_id
    self.trade_type = self.order.type
    self.background = self.order.background
    self.trading_account_id = self.order.trading_account_id
    self.cash_id = self.order.cash_id
    self.trade_time = Time.now
  end

  def set_est_cost
    self.est_cost = cal_est_cost
  end

  def cal_est_cost
    est_price = if market?
      stock.is_cn? ? stock.up_price : self.realtime_price.to_f
    else
      self.limit_price.to_f
    end
    self.est_shares.to_i * est_price
  end

  def est_cost_of_usd
    cal_est_cost * Currency.transform(self.stock.currency.try(:downcase), "usd")
  end

  def set_symbol
    self.symbol = self.stock.symbol
  end

  # 目前aasm version3在传递参数的时候还不够完善，需要我们调用时多传递一个nil，见掉用处
  def update_cost_and_shares(filled, avg_fill_price)
    $pms_logger.info("OrderStatus: 更新前：#{real_shares},#{real_cost},#{status}")  if Setting.pms_logger

      if filled_gte_shares(filled)
        self.attributes = order_status_attrs(filled, avg_fill_price)
        self.save!
        if [:filled, :cancelled, :partial_filled].include?(aasm.to_state)
          self.order.update_real_cost_and_count(filled, avg_fill_price)
          update_average_cost
        end
      end
      complete_order!("orderStatus") if self.order.order_details_complete_count == self.order.order_details.count

    $pms_logger.info("OrderStatus: 更新后：#{real_shares},#{real_cost},#{status}")  if Setting.pms_logger
  end

  def order_status_attrs(filled, avg_fill_price)
    { 
      real_cost: avg_fill_price.to_f * filled.to_f,
      real_shares: filled.to_i,
      status: aasm.to_state,
      trade_time: Time.now,
      updated_by: "orderStatus"
    }
  end

  def reconcile_cost_and_shares(shares, avg_price, time)
    $pms_logger.info("ExecDetails Api: 调平前订单项#{real_shares},#{real_cost},#{status}")  if Setting.pms_logger

    self.attributes = reconcile_attrs(shares, avg_price, time)
    self.save!
    self.order.update_real_cost_and_count(shares, avg_price)
    complete_order!("execDetails") if self.order.order_details_complete_count == self.order.order_details.count
    update_average_cost
    $pms_logger.info("ExecDetails Api: 调平后订单项#{real_shares},#{real_cost},#{status}")  if Setting.pms_logger
  end

  def update_average_cost
    self.update_attributes(average_cost: self.position.try(:average_cost)) if self.sell?
  end

  def sell?
    self.trade_type == 'OrderSell'
  end

  def reconcile_attrs(shares, avg_price, time)
    {
      real_cost: avg_price.to_f * shares.to_f,
      real_shares: shares.to_i,
      status: shares.to_i < self.est_shares ? "partial_filled" : aasm.to_state,
      trade_time: time.to_s.to_estime,
      updated_by: "execDetails"
    }
  end

  def complete_order!(updated_by)
    self.order.finish!
    self.order.update_attributes(updated_by: updated_by)
  end

  def filled_gte_shares(filled)
    filled.to_d >= current_shares
  end

  def current_shares
    self.real_shares.present? ? self.real_shares : 0
  end

  def status_name
    STATUS[self.status.to_sym]
  end

  def est_weight
    (self.est_cost/self.order.est_cost).round(4)*100
  end

  def avg_price
    self.real_shares.to_i == 0 ? 0 : (self.real_cost.to_f/self.real_shares).round(2)
  end

  def realtime_price
    $redis.hget(snapshot_key, "last").to_d rescue 0
  end

  def snapshot_key
    "realtime:" + base_stock_id.to_s
  end

  # 闭式价格由REDIS转成MYSQL
  # def last_close_price_for(date)
  #   date = Date.parse(date) if date.is_a?(String)
  #   IntradayQuote.where(base_id: self.base_stock_id).trade_on(date).first.last_trade_price_only.to_f rescue 0
  # end

  def trading_flag
    trade_type == 'OrderBuy' ? 1 : -1
  end

  # order management
  def market?
    order_type != 'limit' && order_type != "0"
  end

  # Order.last.to_event_json.target!
  def to_event_json
    Jbuilder.new do |json|
      json.(self, :id, :order_id, :real_shares, :est_shares, :real_cost, :avg_price, :status_name, :status)
      json.trade_time trade_time.try(:strftime, Time::DATE_FORMATS[:default])
    end
  end

  def notify
    # Rails.logger.error("notify: #{id}-----#{order_id}-----#{status}")
    EventQueue::OrderTrade.private_publish(user_id, to_event_json.target!)
  end

  def notify_error(message)
    EventQueue::OrderError.private_publish(user_id, json_message(message).target!)
  end

  def json_message(message)
    Jbuilder.new do |json|
      json.(self, :order_id)
      json.message message
    end
  end

  # 計算佣金
  def update_commission(com)
    update_attributes(commission: self.commission.to_d + com.to_d)
  end

  # order_status handler 代理方法
  def previous_total_filled
    real_shares.to_f
  end

  def previous_total_cost
    real_cost.to_f
  end

  def completed?
    self.reload.filled? || self.reload.cancelled? || self.reload.partial_filled?
  end

  def current_basket_id
    basket_id
  end

  def profit
    if average_cost > 0
      (real_cost - average_cost * real_shares) rescue 0
    else
      0
    end
  end

  # 投资概览使用
  def trading_profit
    (realtime_price * real_shares.to_i - real_cost) * trading_flag
  end

  def historical_klass
    return HistoricalQuote if ['us', 'hk'].include?(market.try(:downcase))

    HistoricalQuoteCn
  end

  # 未复权价格
  def historical_price_class
    HistoricalQuotePrice
  end

  before_save :set_market_and_currency, if: "self.market.blank? || self.currency.blank?"
  def set_market_and_currency
    self.market = stock.try(:market_area)
    self.currency = stock.try(:currency)
  end
end
