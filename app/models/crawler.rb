class Crawler
  
  ##
  # An crawler is a class that allows you to easily handle the crawling page from internet
  #
  # Once you want to scratch page from internet, just do as follows:
  #
  #  class MyCrawler < Crawler
  # 
  #    WEBSITES = ["http://www.baidu.com", "http://www.sohu.com"]
  #    
  #    def process_page_results(page)
  #      do something like parse page results and store results in database, etc.
  #    end
  #
  #  end
  #  
  #  then, do as follows:
  #
  #  MyCrawler.new('Mac Safari', MyCrawler::WEBSITES).crawl
  #
  #  so much for this, enjoy yourself.
  #
  
  ##
  # === Parameters
  #
  # [user_agent (String)] A Mechanize user_agent_alias string  (https://github.com/sparklemotion/mechanize/)
  # [websites (Array or String)] A array of urls to be scratched
  #
  def initialize(user_agent, websites = [])
    @agent = Mechanize.new { |a|
      a.user_agent_alias = user_agent || 'Mac Safari'
    }
    @agent.set_proxy Setting.proxy.host, Setting.proxy.port
    @websites = (websites.class == String ? [websites] : websites)
  end
  
  def fetch(website)
    begin
      page = @agent.get(website)
    rescue Mechanize::ResponseCodeError
      $crawler_logger.info("NotFound: fetch website: #{website}")
      page = nil
    rescue Exception => e
      $crawler_logger.info("NotFound: 出异常了，无法解析url: #{website}")
      page = nil
    end
    page
  end
  
  def crawl
    start_at = Time.now
    
    @websites.each do |website|
      $crawler_logger.info("="*20 + "start fetch website: #{website}")
      page = self.fetch(website)
      process_page_results(page) if page
      $crawler_logger.info("="*20 + "end fetch website: #{website}")
    end
    $crawler_logger.info("fetch end: #{Time.now - start_at} #{@websites.inspect}")
  end
  
  def click(options)
    @agent.page.link_with(options).click
  end
  
  def link_with(options)
    @agent.page.link_with(options)
  end
  
  def page
    @agent.page
  end
  
end