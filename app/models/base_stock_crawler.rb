module BaseStockCrawler
  
  class IBCrawler < Crawler

    CRAWL_WEBSITES =  {"NYSE" => "https://www.interactivebrokers.com/en/?f=%2Fen%2Ftrading%2Fexchanges.php%3Fshowcategories%3DSTK%26amp%3Bsortproducts%3DES%26amp%3Bshowproducts%3DAll%26amp%3Bsearch.x%3D63%26amp%3Bsearch.y%3D23%26amp%3Bexch%3Dnyse%26amp%3Bib_entity%3Dllc%26amp%3Bf%3D2222#show",
         "SEHK" => "https://www.interactivebrokers.com/en/?f=%2Fen%2Ftrading%2Fexchanges.php%3Fshowcategories%3DSTK%26amp%3Bsortproducts%3DES%26amp%3Bshowproducts%3DAll%26amp%3Bsearch.x%3D60%26amp%3Bsearch.y%3D24%26amp%3Bexch%3Dsehk%26amp%3Bib_entity%3Dllc%26amp%3Bf%3D2222#show",
          "NASDAQ" => "https://www.interactivebrokers.com/en/?f=%2Fen%2Ftrading%2Fexchanges.php%3Fshowcategories%3DSTK%26amp%3Bsortproducts%3DES%26amp%3Bshowproducts%3DAll%26amp%3Bsearch.x%3D50%26amp%3Bsearch.y%3D24%26amp%3Bexch%3Dnasdaq%26amp%3Bib_entity%3Dllc%26amp%3Bf%3D2222#show"}
    
    attr_reader :exchange

    def initialize(user_agent, websites, opts = {})
      @exchange = opts[:exchange]
      
      @agent = Mechanize.new { |a|
        a.user_agent_alias = user_agent || 'Mac Safari'
      }
      
      @websites = (websites.class == String ? [websites] : websites)
    end
    
    def process_page_results(page)
      deal_current_page(page)
      next_page(page)
    end
    
    def next_page(page)
      text = index_href
      
      if link_with(:text => text)
        $crawler_logger.info("开始抓取第#{text}页数据")
        page = click(:text => text)
        $crawler_logger.info("第#{text}页数据抓取完毕")
        process_page_results(page)
      end
    end
    
    def deal_current_page(page)
      stock_table_list = page.search(".//table[@class='comm_table_background']/tr[@class='linebottom']")
      stock_table_list.each do |stock_line|
        info_nodes = stock_line.search("td")
        bs = BaseStock.fetch_by(ib_id(info_nodes), format(symbol(info_nodes)))
        bs.log_symbol_change
        bs.update_supplement_info(corp_name(info_nodes), ib_symbol(info_nodes), "ib", get_exchange(page.uri.request_uri), format( symbol(info_nodes) ))
      end
    end
    
    def ib_id(stock_info_nodes)
      if stock_info_nodes.at(1).search("a").first.attribute("href").value =~ /action=Details&site=GEN&conid=(.*)','Details'/
        $1
      end
    end
    
    def index_href
      if page.uri.request_uri =~ /sequence_idx%3D(.*)%26amp%3Bsort/
        ($1.to_i/100 + 1).to_s
      else
        '2'
      end
    end
    
    def format(symbol)
      symbol.to_i > 0 ? symbol + ".HK" : symbol
    end
    
    def get_exchange(uri)
      return exchange if exchange.present?
      if uri.include?('exch%3Dnyse%26')
        "NYSE"
      elsif uri.include?('exch%3Dsehk%26')
        "SEHK"
      elsif uri.include?('exch%3Dnasdaq%26')
        "NASDAQ"
      end
    end
    
    def corp_name(stock_info_nodes)
      stock_info_nodes.at(1).text.strip.gsub('&AMP;','&')
    end
  
    def symbol(stock_info_nodes)
      stock_info_nodes.at(2).text.strip
    end
  
    def ib_symbol(stock_info_nodes)
      stock_info_nodes.at(0).text.strip
    end
    
    def self.crawl
      CRAWL_WEBSITES.each { |ex, site| self.new('Mac Safari', site, exchange: ex).crawl }
    end
    
  end
  
  class YahooCrawler < Crawler
    
    CRAWL_URL = 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.industry%20where%20id%20in%20(select%20industry.id%20from%20yahoo.finance.sectors)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback='
    
    ##
    # Return all the industries
    #
    # === Parameters
    #
    # [json_string (String)] A json string that contains base stock info
    # example json_string
    # {"query":{"count":215,"created":"2014-07-08T05:28:54Z","lang":"zh-CN","results":{"industry":[{"id":"112","name":"Agricultural Chemicals","company":[{"name":"Adarsh Plant Protect Ltd","symbol":"ADARSHPL.BO"},{"name":"Agrium Inc","symbol":"AGU.DE"}]}]}}}
    #
    # === Returns
    #
    # [Array] industry array(contains lots of companies)
    #
    def parse_result(json_string)
      JSON.parse(json_string)["query"]["results"]["industry"]
    end
    
    def process_page_results(page)
      industries = parse_result(page.body)
      start = Time.now
      $crawler_logger.info("获取数据结束，开始导入数据库")
      begin
        industries.each do |ins|
          companies = ins["company"]
          next if companies.blank?
          case companies
          when Hash
            next if (companies["symbol"].include?(".") && !(companies["symbol"] =~ /\.HK$/))
            bs = BaseStock.find_or_create_by(symbol: companies["symbol"])
            bs.update_supplement_info(companies["name"], nil, "yahoo", nil, nil)
          when Array
            companies.each do |com|
              next if (com["symbol"].include?(".") && !(com["symbol"] =~ /\.HK$/))
              bs = BaseStock.find_or_create_by(symbol: com["symbol"])
              bs.update_supplement_info(com["name"], nil, "yahoo", nil, nil)
            end
          end
        end
      rescue Exception => e
        $crawler_logger.info("数据如出错了！message: #{e.message}，backtrace: #{e.backtrace.join("\n")}")
        raise
      end
      $crawler_logger.info("数据导入完成，共耗时#{Time.now - start}")
    end
    
  end
  
  class HKBoardLotCrawler < Crawler
    CRAWL_WEBSITES = ['http://sc.hkex.com.hk/TuniS/www.hkex.com.hk/chi/market/sec_tradinfo/stockcode/eisdeqty_pf_c.htm', 'http://sc.hkex.com.hk/TuniS/www.hkex.com.hk/chi/market/sec_tradinfo/stockcode/eisdgems_pf_c.htm']
    
    def process_page_results(page)
      stock_table_list = page.search(".//table[@class='table_grey_border']/tr[@class='tr_normal']")
      stock_table_list.each do |stock_line|
        info_nodes = stock_line.search("td")
        bs = BaseStock.find_by_symbol(format(symbol(info_nodes)))
        bs.update_attributes(c_name: c_name(info_nodes), board_lot: board_lot(info_nodes)) if bs
      end
    end
    
    def symbol(stock_info_nodes)
      stock_info_nodes.at(0).text.strip
    end
    
    def c_name(stock_info_nodes)
      stock_info_nodes.at(1).text.strip
    end
    
    def board_lot(stock_info_nodes)
      stock_info_nodes.at(2).text.strip.gsub(",","")
    end
    
    def format(symbol)
      if symbol.to_i > 9999
        symbol + ".HK"
      else
        symbol.to_i.to_s + ".HK"
      end
    end
    
    def self.crawl
      self.new('Mac Safari', CRAWL_WEBSITES).crawl
    end
  end
  
  class HKExCrawler < Crawler
    
    CRAWL_URL = 'http://www.hkex.com.hk/eng/market/sec_tradinfo/stockcode/eisdeqty_pf.htm'
    
    def process_page_results(page)
      stock_table_list = page.search(".//table[@class='table_grey_border']/tr[@class='tr_normal']")
      stock_table_list.each do |stock_line|
        info_nodes = stock_line.search("td")
        bs = BaseStock.find_by(symbol: format(symbol(info_nodes)))
        bs.update_supplement_info(name(info_nodes), nil, "hkex", 'SEHK', nil) if bs
      end
    end
    
    def symbol(stock_info_nodes)
      stock_info_nodes.at(0).text.strip
    end
    
    def name(stock_info_nodes)
      stock_info_nodes.at(1).text.strip
    end
    
    def format(symbol)
      if symbol.to_i > 9999
        symbol + ".HK"
      else
        symbol.to_i.to_s + ".HK"
      end
    end
    
    def self.crawl
      self.new('Mac Safari', CRAWL_URL).crawl
    end
  end
  
  class ASCNAMECrawler < Crawler
    
    BASE_URL = 'http://xueqiu.com/S/'
    
    def process_page_results(page)
      doc = page.search(".//span[@class='stockName']/strong[@class='stockName']")
      c_name = doc.text.split("(")[0].to_s.split(" ").map{|x| x.humanize}.join(" ")
      symbol = doc.text.split(":")[1].sub(")","").downcase
      bs = BaseStock.find_by_symbol(symbol)
      bs.update_attributes(c_name: c_name) if bs
    end
    
    def self.crawl
      BaseStock.except_sehk.normal.each do |bs|
        self.new('Mac Safari', BASE_URL + bs.symbol).crawl
      end
    end
    
  end
  
end

#BaseStockCrawler::IBCrawler.new('Mac Safari', BaseStockCrawler::IBCrawler::CRAWL_WEBSITES).crawl
#BaseStockCrawler::YahooCrawler.new('Mac Safari', BaseStockCrawler::YahooCrawler::CRAWL_URL).crawl
#BaseStockCrawler::HKBoardLotCrawler.new('Mac Safari', BaseStockCrawler::HKBoardLotCrawler::CRAWL_WEBSITES).crawl
#BaseStockCrawler::HKExCrawler.new('Mac Safari', BaseStockCrawler::HKExCrawler::CRAWL_URL).crawl

#crawling chinese name of American stocks
=begin
BaseStock.where("exchange != 'SEHK'").each do |bs|
  base_url = 'http://xueqiu.com/S/'
  BaseStockCrawler::ASCNAMECrawler.new('Mac Safari', base_url + bs.symbol).crawl
end
=end


