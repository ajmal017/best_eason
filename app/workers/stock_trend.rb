class StockTrend
  @queue = :stock_trend

  def self.perform
    BaseStock.except_neeq.except_x.find_in_batches(batch_size: 2000) do |base_stocks|
      stocks = base_stocks.map { |bs| BaseStock.new(bs.trend!.merge(id: bs.id)) }
      BaseStock.import_trend(stocks)
    end
    
    # 过期个股首页的统计
    $redis.del("stocks_search")
  end
end
