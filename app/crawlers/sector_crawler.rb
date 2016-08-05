class SectorCrawler
  BASE_URL = "http://query.yahooapis.com/v1/public/yql?"
  
  NUM_PER_RERIEVE = 200
  
  RETRY_TIIMES = 1
  
  def self.crawl(symbols, fields = true)
    symbols = symbols.is_a?(String) ? [symbols].to_s : symbols.map(&:ticker).to_s
    url = request_url(symbols[1..-2], fields)
    $crawler_logger.info("RequestUrl: #{url}")
    r = Remote::Base.get(url, proxy: Setting.proxy.url)
    body = $json.decode(r.body)
    [body['query']['results']['stock'], r.try(:success?)]
  rescue
    $crawler_logger.info("Sector Synced Error#####RequestUrl: #{url}, ResponseBody: #{r}")
    [[], false]
  end
  
  def self.request_url(symbols, fields)
    fields = fields ? "symbol,Sector,Industry" : "*"
    url = "q=select #{fields} from yahoo.finance.stocks where symbol" 
    url << " in (" + symbols + ") " 
    url << '&format=json&env=store://datatables.org/alltableswithkeys&callback='
    BASE_URL + URI.encode(url)
  end
  
  def self.import_stocks(stocks)
    imports = stocks.select { |x| x["Sector"] && x["Sector"] != "N/A"}.map{|x| [x["Sector"],  x["Industry"], BaseStock.find_by(ticker: x["symbol"]).id]}
    ImportProxy.import(
      BaseStock, 
      %w(sector industry id), 
      imports, 
      validate: false, 
      on_duplicate_key_update: [:sector, :industry]
    )
  end
  
  def self.retry_key
    "sector_crawler"
  end
  
  def self.retry_times
    $redis.get(retry_key).to_i
  end
  
  def self.retry(stock_ids = nil)
    if retry_times <= RETRY_TIIMES
      $redis.incr(retry_key) && $redis.expire(retry_key, 24.hour)
      Resque.enqueue(StockSector, stock_ids)
    else
      Resque.enqueue(StockScreenerUpdator)
    end
  end
  
  def self.retrieve(symbols)
    stocks, succ = crawl(symbols, fields = true)
    if succ
      stocks = stocks.is_a?(Array) ? stocks : [stocks]
      import_stocks(stocks)
    end
  end

end
