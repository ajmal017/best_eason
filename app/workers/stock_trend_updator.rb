class StockTrendUpdator
  @queue = :stock_trend_updator

  def self.perform
    BaseStock.except_neeq.except_x.find_in_batches(batch_size: 2000) do |base_stocks|
      screeners = base_stocks.select { |bs| bs.trading? }.map { |bs| StockScreener.new(bs.trend_attrs.merge(base_stock_id: bs.id)) }
      StockScreener.import_trend(screeners) if screeners.size > 0
    end
  end
end
