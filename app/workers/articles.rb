class Articles
  @queue = :articles

  def self.perform(url)
    ArticleCrawler.crawl(url) if url.present?
  end
end