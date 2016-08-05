# 作废
class BaseStockYahoo
  @queue = :base_stock_yahoo

  def self.perform
    BaseStockCrawler::YahooCrawler.new('Mac Safari', BaseStockCrawler::YahooCrawler::CRAWL_URL).crawl
  end
end
