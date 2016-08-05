class MD::Feed::Article < MD::Feed
  
  def set_data(attrs={})
    self.recommend_type = :content_article_1
    self.pics = [source.img_url]
    self.title = source.title
    self.items.push(new_item)
  end
  
  def new_item
    MD::ItemArticle.new(id: source.id, name: source.title, type: 'article', category: '专栏')
  end
  
  def self.add(user, source)
    super(:article, nil, source, user: user)
  end

end