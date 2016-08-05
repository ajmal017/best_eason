class MD::Feed::NewsStock < MD::Feed
  
  def private?
    true
  end

  def category
    "自选"
  end

  def pics
    return ["https://cdn.caishuo.com/images/v3/theme_cover.png"] if super.blank?
    super
  end
  
  def news_item
    MD::ItemNews.new(id: source.id, name: source.title, type: :news, ext_data: {source: source.source, category: source.category})
  end
  
  def self.add(user, news, stock)
    feed_type = "news_stock"
    feed = new(user: user, source: news, feed_type: feed_type)
    feed.pics = news.pic_urls
    feed.title = news.title
    feed.items.push(feed.news_item)
    feed.items.push(MD::ItemStock.new(id: stock.id, name: stock.com_name, type: :stock))
    feed.save
    feed
  end
  
end