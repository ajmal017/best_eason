class StockSector
  @queue = :stock_sector

  def self.perform(stock_ids = nil, force = false)
    base_stocks = force ? BaseStock.all : BaseStock.where(sector: nil)
    base_stocks = base_stocks.where(id: stock_ids) if stock_ids 
    base_stocks.find_in_batches(batch_size: SectorCrawler::NUM_PER_RERIEVE).each do |stocks|
      StockSectorCrawler.crawl_by_farady(stocks)
    end
    
    StockSectorCrawler.retry
  end
end
