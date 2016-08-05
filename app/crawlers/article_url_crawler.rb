class ArticleUrlCrawler
  BASE_URL = "http://weixin.sogou.com/gzhjs?cb=sogou.weixin.gzhcb&eqs=HtsUowAgLE0roPNAGBDmIulCOFaK8oBrXZbHYFq4ZxrpHylomrfVY9cM917xK4%2F4Butr9&ekv=9"

  FIRST_PAGE = BASE_URL + "&page=1"

  include Crawlable

  def process_page_results(page)
    if page.body.gsub("\r\n","") =~ /sogou.weixin.gzhcb\((.*)\)/
      h = JSON.parse($1)
      current_page_num = h["page"]
      total_pages = h["totalPages"]
      items = h["items"]
      deal_current_page(items)
      next_page(current_page_num.to_i + 1) if current_page_num.to_i < total_pages.to_i
    end
  end

  def deal_current_page(items)
    items.each do |item|
      doc = Nokogiri::XML(item, nil,'utf-8')
      url = doc.xpath("//item//display//url").text
      title = doc.xpath("//item//display//title").text
      date = doc.xpath("//item//display//date").text
      image_link = doc.xpath("//item//display//imglink").text
      content_168 = doc.xpath("//item//display//content168").text

      if article = Article.fuzzy_search(url: url, title: title)
        # article.update_index_image(image_link)
      else
        Article.create(title: title, abstract: content_168, url: url.gsub(/#rd$/, ""), remote_img_url: image_link, post_date: date)
      end
      $redis.sadd("article_urls", url)
    end
  end

  def next_page(page_num)
    $crawler_logger.info("抓取第#{page_num}页数据")
    website = BASE_URL + "&page=#{page_num}"
    self.class.crawl(website)
  end

  def self.crawl(website)
    CrawlerRunner.new( self.new(website), MechanizeAgentWithoutProxy.new ).crawl if website.present?
  end
end
