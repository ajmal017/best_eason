# 交易结束时计算basket_index
class BasketIndexAfterTradingWorker
  @queue = :basket_index_after_trading_worker

  def self.perform(basket_id)
  	basket = Basket.find(basket_id)
  	return true unless Exchange::Base.by_area(basket.market).workday?
    BasketIndex::RealAfterTrading.new(basket).calculate
  end
end