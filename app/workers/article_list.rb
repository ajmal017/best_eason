class ArticleList
  @queue = :article_list

  def self.perform(url)
    ArticleUrlCrawler.crawl(url) if url.present?
  end
end
