class StockInfoCrawler < Crawler
  
  def process_page_results(page)
     create_stock_info if stock_company.present?
  end
  
  def create_stock_info
    StockInfo.find_or_create_by(symbol: symbol, base_stock_id: stock_id).update_attributes(stock_info_attrs)
  end
  
  def stock_info_attrs
    title_infos.inject({}) { |attrs, title| attrs.merge( get_attr(title) ) }
  end
  
  def get_attr(title)
    if title.text =~ /简介/
      { description: title.next.text.strip }
    elsif title.text =~ /公司电话/
      { telephone: title.next.text.strip }
    elsif title.text =~ /公司网站/
      { site: title.next.text.strip }
    elsif title.text =~ /业务/
      { profession: title.next.text.strip }
    elsif title.text =~ /公司地址/
      { company_address: title.next.text.strip }
    else
      {}
    end
  end
  
  def symbol
    query_symbol.to_i > 0 ? query_symbol.to_i.to_s : query_symbol
  end
  
  def stock_id
    BaseStock.find_by(ib_symbol: symbol).try(:id)
  end
  
  def query_symbol
    page.uri.request_uri.split("/")[2]
  end
  
  def title_infos
    info.search(".//strong[@class='title']")
  end
  
  def info
    res = detail_content
    res = summary_content if res.blank?
    res = company_info if res.blank?
    res
  end
  
  def stock_company
    page.search(".//div[@class='stock-company ']")
  end
  
  def company_info
    stock_company.search(".//p[@class='companyInfo']")
  end
  
  def summary_content
    stock_company.search(".//p[@class='companyInfo summaryContent']")
  end
  
  def detail_content
    stock_company.search(".//p[@class='companyInfo detailContent']")
  end
  
  def self.crawl
    self.new(nil, self.websites).crawl
  end
  
  def self.websites
    (hk_stocks + us_stocks).map { |stock| 'http://xueqiu.com/S/' + stock }
  end
  
  def self.hk_stocks
    BaseStock.where(exchange: 'SEHK').map(&:ib_symbol).map { |stock| "%05d" % stock.to_i }.compact
  end
  
  def self.us_stocks
    BaseStock.where.not(exchange: 'SEHK').map(&:ib_symbol).compact
  end
end