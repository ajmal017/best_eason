class MD::Feed::News < MD::Feed
  
  def set_data(attrs={})
    self.recommend_type = MD::FeedRecommendContent::CATEGORY_MAPPING[source.category]
    self.pics = source.pic_urls
    self.title = source.title
    self.items.push(new_items)
  end
  
  def new_items
    MD::ItemNews.new(id: source.id, name: source.title, type: :news, ext_data: {source: source.source, category: source.category})
  end
  
  def self.add(user, source)
    super(:news, nil, source, user: user)
  end
  
end