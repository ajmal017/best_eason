module MD

  class FeedRecommendContent

    TYPES = {
      content_article_1: {
        name: "专栏",
        feed_type: :article,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 10,
        category: :content,
      },

      content_topic_1: {
        name: "热点",
        feed_type: :topic,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 10,
        category: :content
      },
      content_news_1: {
        name: "要闻",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_2: {
        name: "产经",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_3: {
        name: "大盘",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_4: {
        name: "行业板块",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_5: {
        name: "个股",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_6: {
        name: "博客",
        feed_type: :news,
        limit: 3,
        time_rule: [5,4],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_7: {
        name: "学院",
        feed_type: :news,
        limit: 3,
        time_rule: [3,4],
        ttl_rule: 0,
        weight: 1,
        category: :content
      },
      content_news_8: {
        name: "微信",
        feed_type: :news,
        limit: 3,
        time_rule: [5,4],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_9: {
        name: "快讯",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_10: {
        name: "国际",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_11: {
        name: "投资早餐",
        feed_type: :news,
        limit: 3,
        time_rule: [1],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_12: {
        name: "名家观点",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_13: {
        name: "热点机会",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_14: {
        name: "新股频道",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 3,
        weight: 1,
        category: :content
      },
      content_news_15: {
        name: "研报",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 10,
        weight: 1,
        category: :content
      },
      content_news_16: {
        name: "公告",
        feed_type: :news,
        limit: 3,
        time_rule: [0],
        ttl_rule: 10,
        weight: 1,
        category: :content
      },
      
    }  

    # {"热点" => :content_topic_1}
    CATEGORY_MAPPING = Hash[TYPES.map{|k,v| [v[:name], k]}]

    def self.find(type_name, limit=nil)
      filter = TYPES[type_name.to_sym]
      filter[:data].limit(limit||filter[:limit]).to_a
    end

    def self.generate_all
      data = []
      data << Article.all.to_a
      data << Topic.all.to_a
      
      TYPES.each do |k, v|
        next if v[:feed_type] != :news
        data << MD::Data::SpiderNews.where(category: v[:name], :pic_urls.nin => [nil, []], :content.nin => [nil, ""]).desc(:_id).limit(200).to_a
        data << MD::Data::SpiderNews.where(category: v[:name], :pic_urls => nil, :content.nin => [nil, ""]).desc(:_id).limit(200).to_a
      end
      data.flatten!
      data.sample(data.length).map(&:publish_to_feed_hub)
    end

    
  end

end
