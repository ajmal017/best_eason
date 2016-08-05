# 交易结束时计算basket_index
class BasketIndexAfterTrading
  @queue = :basket_index_after_trading

  def self.perform(market)
    Basket.where(market: market).where(type: ["Basket::Normal", "Basket::Custom"]).completed_and_archived.select(:id).find_each do |basket|
      Resque.enqueue(BasketIndexAfterTradingWorker, basket.id)
    end
  end
end