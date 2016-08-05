class MD::Feed::Banner < MD::Feed

  attr_accessor :pic, :status

  # params[:title], params[:url], params[:pic], params[:status]
  def self.set_banner(attrs={})
    $redis.hmset("feed_banner_1", attrs.slice(:title, :url, :pic, :status).flatten)
  end

  def self.get_banner(force=false)
    records = $redis.hgetall('feed_banner_1')
    return nil if !force and records['status'].blank?
    attrs = {
        id: 'feed_banner_1', 
        feed_type: :banner,
        source_id: 1, 
        title: "这是一个推荐位", 
        category: "置顶",
        pics: ["https://cdn.caishuo.com/static/uploads/article/img/614/aa7728a98155f9de4ee348b033d3ac4e.png"],
        url: "http://m.testing.caishuo.com"
      }.with_indifferent_access.merge(records)
    MD::Feed::Banner.new(attrs)
  end


  def pic
    pics.first
  end

  def pic=(pic_url)
    self.pics = [pic_url]
  end

  def status=(status_value)
    data[:status]=status_value
  end

  def status
    data[:status]
  end

  def pretty_json(opts={})
    {
      id: id,
      source_id: 1,
      feed_type: feed_type,
      feeder: nil,
      title: title,
      category: category,
      content: nil,
      pics: pics,
      url: url,
      items: [],
      display_type: display_type,
      created_at: created_at.iso8601(3)
    }
  end


  def display_type
    1
  end

  def created_at
    Time.now
  end

end