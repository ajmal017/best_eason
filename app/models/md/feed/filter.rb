class MD::Feed::Filter < MD::Feed
  PLATE_FEED_TYPES = %w(filter_zjbklx filter_industry filter_concept)
  # 技术指标
  TECH_INDEX_TYPES = %w(filter_score filter_wr filter_macd)

  def self.add(user_id, feed_type, filter_type_name, title, items)
    url = "#{$mobile_host}/filters/#{filter_type_name.sub(/filter_/, '')}"
    feed = new(user_id: user_id, feed_type: feed_type, title: title, url: url, recommend_type: filter_type_name)

    if PLATE_FEED_TYPES.include?(feed_type.to_s)
      feed.items.push(items.map{|s| MD::ItemPlate.new(s.slice(:type, :name).merge(ext_data: s))})
    else
      feed.items.push(items.map{|s| MD::ItemStock.new(s.slice(:id, :type, :name).merge(ext_data: s.slice(:symbol)))})
    end
    feed.save
    feed
  end

  def source
    url
  end

  def category
    "选股器"
  end

  # 买入卖出方向
  def direction
    return "" unless TECH_INDEX_TYPES.include?(feed_type.to_s)
    recommend_type.to_s.end_with?("_1") ? "buy" : "sell"
  end

  def pretty_json
    super.merge(direction: direction)
  end

end