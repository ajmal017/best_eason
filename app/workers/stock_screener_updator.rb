class StockScreenerUpdator
  @queue = :stock_screener_updator

  def self.perform
    BaseStock.except_neeq.except_x.find_in_batches(batch_size: 2000) do |base_stocks|
      screeners = base_stocks.map { |bs| StockScreener.new(bs.sector_attrs.merge(base_stock_id: bs.id)) }
      StockScreener.import_sector(screeners)
    end
  end
end
