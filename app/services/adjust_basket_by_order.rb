# 实盘大赛，根据用户完成订单的数据对组合进行调仓
class AdjustBasketByOrder
  attr_reader :user_id, :order_id, :prev_basket_id
  CONTEST_ID = 3

  def initialize(order_id)
    @order_id = order_id
    @user_id = order.try(:user_id)
    @prev_basket_id = contest_basket.try(:latest_history_id)
    original_weights
  end

  def call
    unless valid?
      info_log("条件不满足！")
      return false
    end
    update_basket_stocks_by_order
    update_basket_rank
    record_order_id
  end

  # 创建空的大赛组合
  def self.create_contest_basket(user, trading_account_id)
    return false if Basket.normal.finished.where(contest: CONTEST_ID, author_id: user.id).limit(1).present?
    
    params = {
      title: "#{user.username}的实盘大赛组合", author_id: user.id, 
      start_on: Time.now, state: 4, contest: CONTEST_ID, market: :cn
    }
    basket = Basket::Normal.new(params)
    basket.save(validate: false)
    BasketRank.create(basket_id: basket.id, user_id: user.id, contest_id: CONTEST_ID, trading_account_id: trading_account_id, status: 1)
  end

  private

  def valid?
    contest_basket.present? && order.present? && (order.partial_completed? || order.completed?) &&
    trading_account.active? && trading_account.is_a?(TradingAccountPT) && order_not_processed?
  end

  def order_not_processed?
    $redis.hget(redis_key, order.id) != "1"
  end

  def record_order_id
    $redis.hset redis_key, order.id, 1
  end

  def redis_key
    "cs:adjust_basket_by_order"
  end

  def contest_basket
    @contest_basket ||= Basket.normal.finished.where(author_id: user_id, contest: CONTEST_ID).first
  end

  def basket_stocks
    basket_stocks ||= contest_basket.basket_stocks.select(:stock_id, :adjusted_weight, :real_share)
  end

  def order
    @order ||= Order.find_by_id(order_id)
  end

  def order_details
    @order_details ||= order.order_details.select(:base_stock_id, :real_shares, :real_cost, :trade_type)
  end

  def trading_account
    order.trading_account
  end

  def account_total_value
    trading_account.total_property
  end

  def original_weights
    @original_weights ||= contest_basket.stock_weights
  end

  def original_cash_weight
    original_weights[Stock::Cash.id]
  end

  def original_shares
    @original_shares ||= basket_stocks.map{|bs| [bs.stock_id, bs.real_share] }.to_h
  end

  def trade_stock_shares
    @trade_stock_shares ||= order_details.map{|od| [od.base_stock_id, od.real_shares.to_i * od.trading_flag]}.to_h
  end

  def trade_stock_prices
    @trade_stock_prices ||= order_details.map{|od| [od.base_stock_id, od.avg_price] }.to_h
  end

  def new_stock_shares
    all_stock_ids.map do |stock_id|
      shares = ( original_shares[stock_id] || 0 ) + ( trade_stock_shares[stock_id] || 0 )
      error_log("shares 出现异常！") if shares < 0  # todo
      [stock_id, shares]
    end.select{|_, shares| shares > 0 }.to_h
  end

  def all_stock_ids
    (original_shares.keys + trade_stock_shares.keys).uniq
  end

  def stock_prices
    @stock_prices ||= all_stock_ids.map do |stock_id|
      price = trade_stock_prices[stock_id] ? trade_stock_prices[stock_id] : Rs::Stock.find(stock_id).realtime_price
      [stock_id, price]
    end.to_h
  end

  def new_weights
    @new_weights ||= cal_weights_by_shares(new_stock_shares)
  end

  def new_cash_weight
    new_weights[Stock::Cash.id]
  end

  def old_weights
    @old_weights ||= cal_weights_by_shares(original_shares)
  end

  def cal_weights_by_shares(stock_shares)
    stock_values = stock_shares.map do |stock_id, shares|
      price = stock_prices[stock_id] # todo: nil?
      [stock_id, shares * price]
    end.to_h
    # todo: account_total_value  多单同时成交时问题？
    weights = stock_values.map do |stock_id, value|
      weight = account_total_value.zero? ? 0 : value/account_total_value
      [stock_id, weight]
    end.to_h
    Stock::Cash.id_weights_with(weights)
  end

  def low_acc_weights
    @low_acc_weights ||= BasketIndex::RealtimeWeight.send(:to_low_accurate, new_weights)
  end

  def new_basket_stocks
    basket_stocks = []
    new_weights.select{|sid, _| sid>0 }.each do |stock_id, weight|
      basket_stocks << BasketStock.new(
        stock_id: stock_id, basket_id: contest_basket.id, weight: low_acc_weights[stock_id], 
        adjusted_weight: weight, ori_weight: weight, real_share: new_stock_shares[stock_id]
      )
    end
    basket_stocks
  end

  def update_basket_stocks_by_order
    ActiveRecord::Base.transaction do
      contest_basket.basket_stocks = new_basket_stocks
      contest_basket.update(modified_at: order.updated_at, parent_id: contest_basket.latest_history_id)
      contest_basket.copy_to_history_version(false)
    end
    create_adjustment
  rescue
    error_log("update transaction error! ")
  end

  def create_adjustment
    # 只记录交易股票
    adjustment = BasketAdjustment.create({
      state: BasketAdjustment::STATES[:normal], prev_basket_id: prev_basket_id, 
      next_basket_id: contest_basket.latest_history_id, original_basket_id: contest_basket.id
    })
    # need check: contest_basket
    adjust_logs = trade_stock_shares.keys.map do |stock_id|
      BasketAdjustLog.new(
        basket_adjustment_id: adjustment.id, stock_id: stock_id, 
        weight_from: original_weights[stock_id] || 0, weight_to: new_weights[stock_id], 
        stock_price: stock_prices[stock_id], realtime_weight_from: old_weights[stock_id] || 0
      )
    end
    adjust_logs << BasketAdjustLog.new(
        basket_adjustment_id: adjustment.id, weight_from: original_cash_weight, 
        weight_to: new_cash_weight
      )
    BasketAdjustLog.import(adjust_logs, validate: true)
  end

  def update_basket_rank
    rank = Contest.find(CONTEST_ID).basket_rank_of(user_id)
    rank.set_analysis_infos
  rescue
    error_log("查找rank出错！")
  end

  def error_log(content)
    log("error", content)
  end

  def info_log(content)
    log("info", content)
  end

  def log(level, content)
    $adjust_basket_by_order_loger.send level, "#{Time.now} order_id:#{order_id} #{content}"
  end

end