class UserStockProfit < ActiveRecord::Base
  belongs_to :user
  belongs_to :stock, foreign_key: :stock_id, class_name: BaseStock
  belongs_to :trading_account

  validates :user_id, :trading_account_id, :stock_id, presence: true

  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :by_stock, -> (stock_id) { where(stock_id: stock_id) }
  scope :account_with, ->(account_id) { where(trading_account_id: account_id) }
  scope :date_gte, -> (date) { where("date >= ?", date) }
  scope :date_lte, -> (date) { where("date <= ?", date) }

  def self.archived_profit_and_cost(stock_id, user_id, account_id = nil)
    stock_profits = by_user(user_id).by_stock(stock_id)
    stock_profits = stock_profits.account_with(account_id) if account_id
    return 0,0 if stock_profits.blank?
    stock_profits.map{|p| [p.total_profit, p.total_cost]}.transpose.map{|arr| arr.sum.to_f}
  end

  # 只包含已实现盈亏，不包括未实现盈亏，需要外部相加
  def total_profit
    total = total_pnl + today_pnl
    total = total + tws_pnl if !stock.is_cn?
    total
  end

  def total_cost
    total = total_buyed + today_buyed
    total = total + tws_buyed
    total
  end

  # 每日定时跑，不包含交易时当天的
  def total_pnl
    super.to_f
  end

  # 每日定时跑，不包含交易时当天的
  def total_buyed
    super.to_f
  end

  def today_pnl
    today_selled - today_buyed
  end

  def today_buyed
    @today_buyed ||= order_details.buyed.map(&:real_cost).sum.to_f
  end

  def today_selled
    @today_selled ||= order_details.selled.map(&:real_cost).sum.to_f
  end

  def order_details
    trade_times = stock.profit_time_range
    order_details = OrderDetail.account_with(trading_account_id).stock_with(stock_id).trade_time_range(trade_times[:start], trade_times[:end]).profited
  end

  def tws_pnl
    tws_selled - tws_buyed
  end

  def tws_buyed
    tws_details.buyed.map(&:total_price).sum.to_f
  end

  def tws_selled
    @tws_selled ||= tws_details.selled.map(&:total_price).sum.to_f
  end

  def tws_details
    trade_times = stock.profit_time_range
    order_details = exec_class.account_with(trading_account_id).by_stock(stock_id)
                           .time_range(trade_times[:start], trade_times[:end]).profited
                           .select("avg_price * shares as total_price")
  end

  def self.calculate(account, date)
    # 先取全部的，后面可改成只取最近1天的
    stock_ids = Position.account_with(account.id).select(:base_stock_id).map(&:base_stock_id).uniq
    stock_ids.each do |stock_id|
      stock_profit = self.find_or_initialize_by(user_id: account.user_id, trading_account_id: account.id, stock_id: stock_id)
      stock_profit.update(total_pnl: stock_profit.cal_total_pnl, total_buyed: stock_profit.cal_total_buyed)
    end
  end

  def cal_total_pnl
    total_selled - total_buyed
  end

  def cal_total_buyed
    @total_buyed ||= total_details.buyed.map(&:real_cost).map(&:to_f).sum.to_f
  end

  def total_selled
    @total_selled ||= total_details.selled.map(&:real_cost).map(&:to_f).sum.to_f
  end

  # 最初版本使用ExecDetail，由于数据问题，改用OrderDetail
  def total_details
    end_time = exchange.exec_end_trade_time
    OrderDetail.account_with(trading_account_id).stock_with(stock_id).fill_finished
      .trade_time_lte(end_time).select(:real_cost)
  end

  private
  def exchange
    @exchange ||= Exchange::Base.by_area(stock.market_area)
  end

  def exec_class
    trading_account.exec_class
  end
end