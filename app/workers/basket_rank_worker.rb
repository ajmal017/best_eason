class BasketRankWorker
  @queue = :basket_rank
  
  def self.perform
    exchange = Exchange::Base.by_area("cn")
    return "非交易日" unless exchange.workday?

    # BasketRankCache.load_data
    # shipan一天2次，11点、15点的定时，晚上的不跑
    # BasketRank.load_shipan_ret(3) if [11, 15].include?(Time.now.hour)
  end
  
end
