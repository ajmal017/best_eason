#class StockQuote::Stock
  # 实时数据返回Currency字段
#  FIELDS << 'Currency'
#end

#module RestClient
#  class << self
    # RestClient在生产环境抓取Yahoo数据时使用代理
#    def get_with_proxy(url, headers={}, &block)
#      if (url.match(/yahoo/) || headers[:proxy]) 
#        self.proxy = Setting.proxy.url and url.gsub!(/^https/,'http')
#      end
#      get_without_proxy(url, headers, &block)
#    end

#    def post_with_proxy(url, payload, headers={}, &block)
#      self.proxy = Setting.proxy.url if headers[:proxy]
#      post_without_proxy(url, payload, headers, &block) 
#    end

#    alias_method_chain :get, :proxy
#    alias_method_chain :post, :proxy
#  end
#end

#module YahooFinance

  # 重写YahooFinance底层方法以及优化代码,切忌不要重写环境变量http_proxy,
  # 因为很多Gem底层使用RestClient,造成莫名其妙的Bug
  #def YahooFinance.retrieve_raw_historical_quotes(symbol, startDate, endDate)
  #  return [] if startDate > endDate

  #  proxy = true ? URI.parse(Setting.proxy.url) : OpenStruct.new

  #  Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).start("itable.finance.yahoo.com",80) do |http|

  #    body = http.get(itable_query_url(symbol, startDate, endDate)).body.chomp

  #    return [] if body !~ /Date,Open,High,Low,Close,Volume,Adj Close/

  #    CSV.parse(body).drop(1)
  #  end
  #end

  #def YahooFinance.itable_query_url(symbol, start_date, end_date)
  #  "/table.csv?s=#{symbol}&g=d".tap do |url|
  #    if start_date
  #      url << "&a=#{start_date.month.pred}&b=#{start_date.mday}&c=#{start_date.year}"
  #    end

  #    if end_date
  #      url << "&d=#{end_date.month.pred}&e=#{end_date.mday}&f=#{end_date.year.to_s}"
  #    end
  #  end
  #end
#end
