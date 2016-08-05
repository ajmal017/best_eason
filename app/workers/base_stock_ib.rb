class BaseStockIb
  @queue = :base_stock_ib

  def self.perform
    ["IBCrawler", "HKBoardLotCrawler", "HKExCrawler", "ASCNAMECrawler"].each do |crawler|
      ("BaseStockCrawler::" + crawler).constantize.crawl
    end
    
    # 抓取股票简介信息
    StockInfoCrawler.crawl

    # 更新是否合法字段Normal
    max_date = BaseStock.maximum(:date)
    hide_symbols = ['HBANP', '4338.HK']

    BaseStock.where("date >= ?", max_date - 2.days).where.not(symbol: hide_symbols).update_all(normal: true)
    # 3日以上数据设置为不合法
    BaseStock.where("date < ?", max_date - 2.days).update_all(normal: false)
    # OLD以及OLD.HK结尾的数据不合法
    BaseStock.where("symbol like '%\.OLD' or symbol like '%\.OLD\.HK'").update_all(normal: false)
    # HBANP 4338.HK 隐藏
    BaseStock.where(symbol: hide_symbols).update_all(normal: false)
    # ib_id不合法
    BaseStock.where(ib_id: nil).update_all(normal: false)
    # DATE为NIL的设置不合法
    BaseStock.where(date: nil).update_all(normal: false)
  end
end
