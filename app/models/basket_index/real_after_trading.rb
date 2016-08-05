# 交易刚结束后，根据实时数据先计算一遍指数
class BasketIndex::RealAfterTrading < BasketIndex::Real

  def initialize(basket)
    exchange = Exchange::Base.by_area(basket.market)
    date = exchange.today
    raise BasketIndex::InvalidTimeError, "当前时间不对，不能跑此basket的index" unless exchange.workday? && exchange.market_close?

    super(basket, date)
  end

  private
  def trading_stocks_close_prices(stock_ids)
    BasketIndex::StockReturn.stocks_realtime_prices(stock_ids)
  end

  def holding_stock_rets(stock_ids)
    BasketIndex::StockReturn.realtime_rets(stock_ids)
  end
end