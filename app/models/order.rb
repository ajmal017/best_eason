require 'active_support/builder' unless defined?(Builder)
class Order < ActiveRecord::Base

  STATUS = {
    unconfirmed: "未确认", 
    confirmed: "已报", 
    partial_completed: "部分完成",
    completed: "交易完成", 
    cancelled: "交易取消", 
    expired: "失效", #过期
    error: "出错",
    cancelling: "取消中"
  }

  TRADE_TYPES = [ "OrderBuy", "OrderSell", "OrderAdjust"]
  EXTERNAL_SOURCES = ["itn"]
  
  scope :buyed, -> { where("real_cost > 0") }
  scope :unconfirmed, -> { where(:status => "unconfirmed") }
  scope :normal, -> { where("status <> 'unconfirmed'") }
  scope :created_at_gte, -> (date_str) { date_str.present? ? where("created_at >= ?", Date.parse(date_str)) : all }
  scope :created_at_lte, -> (date_str) { date_str.present? ? where("created_at <= ?", Date.parse(date_str) + 1) : all}
  scope :search_by_created_at, -> (start_date, end_date) { created_at_gte(start_date).created_at_lte(end_date) }
  scope :of_user, -> ( user ) { user.respond_to?(:id) ? where(user_id: user.id) : where(user_id: user) }
  scope :of_type, -> ( trade_type ) { where(type: "OrderBuy") }
  scope :stocks, -> { where(instance_id: 'others') }
  scope :baskets, -> { where("instance_id <> 'others'") }
  scope :by_account, ->(account_id) { where(trading_account_id: account_id) }
  scope :traded, -> { where(status: ["completed", "partial_completed"]) }
  scope :by_date, -> (date){ where('left(updated_at, 10) = ?', date.to_s(:db)) }
  scope :today, -> { by_date(Time.now.to_date) }

  belongs_to :basket
  belongs_to :user
  belongs_to :trading_account
  
  # 红包项目暂时添加
  attr_accessor :user_binding

  # 订单详情
  has_many :order_details, dependent: :destroy
  has_one :stock_detail, -> { where instance_id: 'others' }, class_name: "OrderDetail"
  accepts_nested_attributes_for :order_details

  # 仓储
  has_many :positions, foreign_key: 'instance_id', primary_key: 'instance_id'
  has_many :stock_share_logs, class_name: 'OrderStockShare', foreign_key: 'instance_id', primary_key: 'instance_id', dependent: :destroy
  has_many :order_logs
  
  has_many :order_errs

  validates :est_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :basket_mount, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :instance_id, presence: true
  validates :user_id, presence: true
  validates :trading_account_id, presence: true
  validate do
    errors.add(:trading_account, '当前交易账户不能购买此市场股票') unless trading_account.broker.market.include?(market)
  end

  before_validation :set_est_cost, :set_market, :set_expiry, if: Proc.new {|o| o.new_record?}
  validate :stocks_shares_is_right, if: Proc.new {|o| o.new_record? && o.buy_order? }

  #测试下单
  include OrderCreateTester

  #状态机
  include OrderStateable
  
  #订单管理
  include OrderManageable
  # CA[0-9A-F]00001312

  include OrderIdable
  
  def set_est_cost
    self.est_cost = cal_est_cost
  end

  def cal_est_cost
    self.order_details.map(&:cal_est_cost).sum
  end
  
  def est_cost_of_usd
    self.order_details.map{|od| od.est_cost_of_usd }.sum
  end
  
  def current_real_cost
    self.real_cost.present? ? self.real_cost : 0
  end

  def currency_unit
    Basket::CURRENCY_UNITS[market.to_sym]
  end
  
  def update_real_cost_and_count(filled, avg_fill_price)
    self.with_lock do
      self.real_cost = self.current_real_cost + avg_fill_price.to_d * filled.to_d
      self.order_details_complete_count = self.order_details_complete_count + 1
      self.save!
    end
  end

  def filled_order_details_by_updated_at(time)
    self.order_details.has_filled.where("updated_at > ?", time).order("updated_at asc")
  end
  
  #for test
  def sell(percent)
    #todo modify: users inputs : basket_mount , details attrs
    attrs = {instance_id: self.instance_id, user_id: self.user_id, basket_id: self.basket_id, 
             basket_mount: self.basket_mount}
    order_details_attributes = {}
    self.order_details.each_with_index do |order_detail, index|
      order_details_attributes[index.to_s] = {base_stock_id: order_detail.base_stock_id, est_shares: selled_shares(order_detail, percent)}
    end
    attrs["order_details_attributes"] = order_details_attributes
    OrderSell.create(attrs)
  end
  
  def selled_shares(order_detail, percent)
    ((order_detail.real_shares.to_i * percent.to_f)/100).to_i == 0 ? 1 : ((order_detail.real_shares.to_i * percent.to_f)/100).to_i
  end
  
  def completed?
    self.status == "completed"
  end

  def status_name
    STATUS[self.status.to_sym]
  end

  def last_filled_order_details(limit = 3)
    self.order_details.where("real_shares > 0").order("updated_at desc").limit(limit).reverse
  end
  
  include Xmlable
  def to_xml
    options = {
      only: [],
      methods: [:instance_order_id, :format_expiry, :advAccount, :subAccount],
      root: 'basket', 
      dasherize: false,
      skip_types: true,
      include: [:order_details => {
        only: [],
        methods: [:ib_symbol, :exchange, :realtime_price, :size], 
        tag_names: {ib_symbol: 'symbol', realtime_price: 'price', order_detail: 'order'},
        without_root: true
      }],
      tag_names: {instance_order_id: 'basketId', format_expiry: 'expiry'}
    }
    super(options)
  end

  def to_xml_msg
    xm = ::Builder::XmlMarkup.new()
    xm.instruct!
    xm.basket {
      xm.basketId(instance_order_id)
      xm.expiry(format_expiry)
      xm.advAccount(advAccount)
      xm.subAccount(subAccount)
      self.order_details.each do |detail|
        xm.order {
          xm.symbol(detail.ib_symbol)
          xm.exchange(detail.exchange)
          xm.price(detail.realtime_price)
          xm.size(detail.size)
          xm.limitPrice(detail.limit_price) if detail.limit_price.present?
          xm.GTD(gtd_time) if gtd? && !detail.market?
        }
      end
    }
  end
  
  def instance_order_id
    "#{self.instance_id.to_s}:#{self.id.to_s}"
  end

  def self.excuting_orders_by(user_id, basket_ids)
    confirmed.where(user_id: user_id, instance_id: basket_ids).order("id desc")
  end

  def executing_stocks_count
    order_details.executing.count
  end
  
  def expiration
    Exchange::Base.by_area(market).latest_close_market_time
  end
  
  def set_expiry
    self.expiry = self.expiration
  end

  def gtd_time
    self.order_details.first.try(:stock).try(:long_time_from_now)
  end
  
  def set_market
    first_stock = self.order_details.first.stock
    self.exchange = first_stock.exchange
    self.market = first_stock.market_area
    self.product_type = self.basket_id.blank? ? "stock" : "basket"
  end
  
  def format_expiry
    if self.order_details.first.try(:stock).try(:market_area) == :hk
      self.expiry.to_s_full
    else
      self.expiry.to_s_full.to_estime.to_s_full 
    end
  end


  def notify_complete
    #EventQueue::OrderFinish.private_publish(user_id, {id: id, state: status, status_name: status_name}) rescue nil
  end
  
  # Just for Testing
  def test_queue(index=nil)
    ods = order_details

    20.times do |i|
      od = ods[index||rand(ods.size)]
      od.real_shares ||= 0 
      od.real_cost ||= 0
      od.trade_time ||= Time.now

      od.real_shares += rand(10)
      od.real_cost += (rand(300)/100.0)
      od.notify
      sleep(0.2)

    end

    ods.each do |od|
      od.real_shares ||= 0 
      od.real_cost ||= 0
      od.trade_time ||= Time.now

      od.real_shares = od.est_shares
      od.real_cost = od.est_cost
      od.status = 'filled'
      od.notify

      sleep(0.3)
    end

    EventQueue::OrderFinish.private_publish(user_id, {id: id})
  end
  
  def update_commission(com)
    self.update_attributes(commission: self.commission.to_d + com.to_d)
  end
  

  def retry
    OrderStatusPublisher.publish(self.to_xml_msg)
  end

  def self.add_market
    self.find_each do |order|
      order.update(exchange: order.order_details.first.stock.exchange, market: order.order_details.first.stock.is_sehk? ? 'hk' : 'us', product_type: order.basket_id.blank? ? "stock" : "basket")
    end
  end

  def simulated_fee
    fee_class = "Caishuo::Utils::Fee::#{self.market.capitalize}".safe_constantize
    self.order_details.map do |od|
      current_price = od.est_cost/od.est_shares
      fee_class.new(price: current_price, shares: od.est_shares).money
    end.sum.round(2).to_f
  end
  
  after_create :set_trading_since, if: "self.trading_account.present? && self.trading_account.trading_since.blank?"
  def set_trading_since
    trading_account.update(trading_since: Date.today)
  end

  def market_cn?
    market == "cn"
  end

  def product_type_desc
    basket? ? "组合" : "股票"
  end

  def est_shares
    order_details.inject(0){|sum, od| sum += od.est_shares.to_i}
  end

  def real_shares
    order_details.inject(0){|sum, od| sum += od.real_shares.to_i}
  end

  def external?
    EXTERNAL_SOURCES.include? source
  end

  def self.trade_between(account_id, begin_time, end_time)
    by_account(account_id).traded.joins(:order_details)
      .where("order_details.trade_time >= ? and order_details.trade_time <= ?", begin_time, end_time)
  end

  private
  #验证买卖的数量是否board_lot的整数倍
  def stocks_shares_is_right
    order_stocks = BaseStock.where(id: self.order_details.map(&:base_stock_id)).map{|s| [s.id, s]}.to_h
    order_want_stocks_shares = self.order_details.map{|x| [x.base_stock_id, x.est_shares]}.to_h
    wrong_stocks = order_want_stocks_shares.select{|stock_id, shares| shares % order_stocks[stock_id].get_board_lot != 0}
    errors.add(:wrong_count_by_board_lot, '股票数量不符合系统要求，请刷新页面或联系客服！') if wrong_stocks.present?
  end
end
