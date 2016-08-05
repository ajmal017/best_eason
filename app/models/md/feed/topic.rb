class MD::Feed::Topic < MD::Feed
  
  def set_data(attrs={})
    self.recommend_type = "content_topic_1"
    self.pics = [source.img_url]
    self.items.push(new_item)
    self.title = source.sub_title
  end
  
  def new_item
    MD::ItemTopic.new(id: source.id, name: source.sub_title, type: 'topic', tags: [source.title])
  end
  
  def self.add(source)
    super(:topic, nil, source)
  end
  
end