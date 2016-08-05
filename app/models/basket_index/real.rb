# 每天实际指数计算 with cash
class BasketIndex::Real
  attr_reader :basket, :date, :market_area, :stock_weights, :last_day

  def initialize(basket, date)
    @basket = basket
    @date = date
    @market_area = basket.market
    @stock_weights = get_stock_weights
    @last_day = ClosedDay.get_work_day(@date - 1, @market_area)
  end

  def calculate
    return false unless basket.completed? && ClosedDay.is_workday?(date, basket.market)

    last_day_basket_index = basket.basket_indices.find_by(date:last_day)

    ret = cal_basket_return
    log_current_weights

    calculate_index(ret, last_day_basket_index)
  end

  private

  def get_stock_weights
    basket.initial_stock_weights_by_date(date)
  end

  def calculate_index(ret, last_day_index_record)
    ((1 + ret) * last_day_index(last_day_index_record)).round(6)
  end

  def cal_basket_return
    holding_pnl + trading_pnl
  end

  def holding_pnl
    last_day_weights = BasketWeightLog.stock_adjusted_weights(basket.id, last_day)
    return 0 if last_day_weights.blank?

    stock_rets = holding_stock_rets(last_day_weights.keys)
    stock_rets.map{|stock_id, s_return| (last_day_weights[stock_id]||0) * s_return}.sum || 0
  end

  # 多次调仓trading pnl
  def trading_pnl
    return 0 if adjust_logs.blank?
    adjust_logs.map{|log| log.pnl(trading_stocks_prices[log.stock_id]) }.sum.to_f
  end

  def trading_stocks_prices
    @trading_stocks_prices ||= trading_stocks_close_prices(adjust_logs.map(&:stock_id))
  end

  def last_adjustment_stocks_rets
    last_adjustment_id = adjustment_ids.last
    stock_ids = stock_weights.keys
    last_adjustment_logs = adjust_logs.select{|log| stock_ids.include?(log.stock_id) && log.basket_adjustment_id == last_adjustment_id}
    rets = last_adjustment_logs.map do |log|
      ret = log.ret_by_price(trading_stocks_prices[log.stock_id])
      [log.stock_id, ret]
    end.to_h
  end

  def adjustment_ids
    @adjustment_ids ||= BasketAdjustment.calculable.where(next_basket_id: history_baskets.map(&:id)).map(&:id)
  end

  def adjust_logs
    @adjust_logs ||= BasketAdjustLog.where(basket_adjustment_id: adjustment_ids).except_cash 
  end

  def history_baskets
    @history_baskets ||= basket.history_baskets_by(date)
  end

  def trading_stocks_close_prices(stock_ids)
    BasketIndex::StockReturn.stocks_close_prices(stock_ids, date)
  end

  def holding_stock_rets(stock_ids)
    BasketIndex::StockReturn.calculate(stock_ids, date, last_day, market_area)
  end

  def last_day_index(last_index_record)
    last_index_record.try(:index) || 1000
  end

  def log_current_weights
    stock_rets = history_baskets.blank? ? holding_stock_rets(stock_weights.keys) : last_adjustment_stocks_rets
    adjust_stocks_weight(stock_rets)
  end

  def adjust_stocks_weight(stock_returns)
    BasketIndex::RealtimeWeight.adjust_by(stock_weights, stock_returns)
    set_adjusted_weights
  end

  def set_adjusted_weights
    BasketIndex::RealtimeWeight.record_adjust_weights(basket, stock_weights, date)
  end
end