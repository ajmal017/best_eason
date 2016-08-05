class StockSectorCrawler
  BASE_URL = "http://query.yahooapis.com/v1/public/yql?"
  
  NUM_PER_RERIEVE = 200
  
  RETRY_TIIMES = 1
  
  include Crawlable
  
  def process_page_results(page)
    stocks, succ = page.present? ? [$json.decode(page.body)['query']['results']['stock'], page.try(:success?)] : [[], false]
    if succ
      stocks = stocks.is_a?(Array) ? stocks : [stocks]
      import_stocks(stocks)
    end
  end
  
  def import_stocks(stocks)
    imports = stocks.select { |x| x["Sector"] && x["Sector"] != "N/A"}.map{|x| [x["Sector"],  x["Industry"], BaseStock.find_by(ticker: x["symbol"]).id, Sector.find_sector_code_by(x["Sector"], x["Industry"])]}
    ImportProxy.import(
      BaseStock, 
      %w(sector industry id sector_code), 
      imports, 
      validate: false, 
      on_duplicate_key_update: [:sector, :industry, :sector_code]
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
  
  def self.crawl_by_farady(symbols)
    CrawlerRunner.new(self.new(request_url(symbols)), RemoteFaradyAgent.new).crawl
  end
  
  def self.request_url(symbols, fields = true)
    symbols = symbols.is_a?(String) ? [symbols].to_s : symbols.map(&:ticker).to_s
    fields = fields ? "symbol,Sector,Industry" : "*"
    url = "q=select #{fields} from yahoo.finance.stocks where symbol" 
    url << " in (" + symbols[1..-2] + ") " 
    url << '&format=json&env=store://datatables.org/alltableswithkeys&callback='
    BASE_URL + URI.encode(url)
  end
  
end
