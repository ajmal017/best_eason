module MD
  # Feed推荐池
  class FeedHub
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'feed_hubs'

    # embeds_one :rule, class_name: "MD::FeedRule"

    # feed类型
    field :feed_type

    # 推荐类型
    field :recommend_type

    # 推荐种类 :content, :filter, :event
    # MD::FeedRule::FEED_TYPES
    field :recommend_category

    field :source_type
    field :source_id
    field :title, type: String
    field :data, type: Hash, default: {}
    field :reader_ids, type: Array, default: []
    field :clicker_ids, type: Array, default: []
    field :clicks_count, type: Integer, default: 0
    field :random_key, type: Integer
    field :stock_ids, type: Array, default: []
    field :pics, type: Array, default: [] # 图片数组
    field :time_rule, type: Array, default: []
    field :expired_at, type: DateTime

    field :url
    field :state, type: Integer, default: 1
    field :weight, type: Integer, default: 1

    # 当前时间段可见的
    scope :visible, -> { normal.where(:expired_at.gt => Time.now, :time_rule.in =>  MD::FeedRule::TimeRule.get_rule).desc(:weight, :created_at) }
    scope :normal, -> { where(state: STATES[:normal]) }
    scope :white_attrs, -> { only(:feed_type, :recommend_type, :recommend_category, :source_type, :source_id, :title, :data, :stock_ids, :pics, :url, :weight) }

    validates :feed_type, presence: true
    validates :recommend_category, presence: true
    validates :recommend_type, presence: true
    validates :source_type, presence: true
    validates :source_id, presence: true, uniqueness: { scope: [:source_type, :feed_type] }
    validates_numericality_of :weight, greater_than_or_equal_to: 0, less_than_or_equal_to: 10, only_integer: true

    # Index
    # db.feed_hubs.createIndex( { "expired_at": 1 }, { expireAfterSeconds: 0 } )
    # index({ expired_at: 1 }, { expireAfterSeconds: 0 })

    # 每次推荐的Feed数目

    # DB中取的FEEDS数量
    FEEDS_COUNT_CONTENT_DB = 10
    FEEDS_COUNT_CONTENT = 5

    # 个股分类 只选取用户自选股和持仓股票
    FEEDS_COUNT_CONTENT_STOCK_DB = 10
    FEEDS_COUNT_CONTENT_STOCK = 3

    FEEDS_COUNT_FILTER_DB = 4
    FEEDS_COUNT_FILTER = 1

    FEEDS_COUNT_EVENTS_DB = 4
    FEEDS_COUNT_EVENTS = 1

    FEEDS_COUNT_TOTAL = FEEDS_COUNT_CONTENT + FEEDS_COUNT_FILTER + FEEDS_COUNT_EVENTS + FEEDS_COUNT_CONTENT_STOCK

    FEED_MAPPING = {
      news: 'MD::Data::SpiderNews',
      article: 'Article',
      topic: 'Topic'
    }

    STATES = {
      normal: 1,
      deleted: 2
    }

    # 从FeedHub中的Feed事件 筛选出用户感兴趣的Feed, 并放入到用户的feed流中
    def self.search(user_id, uuid = nil)
      return if user_id.blank? && uuid.blank?

      user_id = user_id.to_i
      uuid = "uuid_#{uuid}"

      user = MD::User.find(user_id) rescue nil
      user = MD::User.new(id: uuid) if user.blank?
      return if user.blank?

      # 获得当前用户的持仓、自选股
      if user.persisted?
        position_stock_ids = Position.where(user_id: user.id).where("shares > 0").pluck(:base_stock_id).uniq
        following_stock_ids = Follow::Stock.where(user: user.id).pluck(:followable_id).uniq
      else
        position_stock_ids, following_stock_ids = [], []
      end

      feed_hubs = []
      feed_hubs.push(*__search_filter(user.id))
      feed_hubs.push(*__search_events(user.id))
      feed_hubs.push(*__search_stock_content(user.id, position_stock_ids, following_stock_ids))
      feed_hubs.push(*__search_content(user.id, FEEDS_COUNT_TOTAL - feed_hubs.length))

      feeds = generate_feeds(user, feed_hubs, position_stock_ids, following_stock_ids)
      feeds = feeds.blank? ? last_feed(user) : feeds
      feeds.prepend(__search_banner).compact
    end

    # 指定Feed Banner
    def self.__search_banner
      MD::Feed::Banner.get_banner
    end

    def self.__search_filter(user_id)
      MD::FeedHub.visible.white_attrs.where(recommend_category: 'filter').where(:reader_ids.ne => user_id).desc('_id').limit(FEEDS_COUNT_FILTER_DB).to_a.sample(FEEDS_COUNT_FILTER)
    end

    def self.__search_content(user_id, limit = nil)
      if auto_status_opened?
        MD::FeedHub.visible.white_attrs.where(recommend_category: 'content', :recommend_type.nin => ['content_news_4', 'content_news_5']).where(:reader_ids.ne => user_id).desc("_id").limit(FEEDS_COUNT_CONTENT_DB).to_a.sample(limit||FEEDS_COUNT_CONTENT)
      else
        MD::FeedHub.visible.white_attrs.where(recommend_category: 'content', :weight.in => ::MD::FeedRule::WeightRule::MANUAL_RULES).where(:reader_ids.ne => user_id).desc("_id").limit(FEEDS_COUNT_CONTENT_DB).to_a.sample(limit||FEEDS_COUNT_CONTENT)
      end
    end


    def self.__search_stock_content(user_id, position_stock_ids=[], following_stock_ids=[])
      MD::FeedHub.visible.white_attrs.where(recommend_category: 'content', recommend_type: 'content_news_5')
      .where(:reader_ids.ne => user_id, :stock_ids.in => (position_stock_ids + following_stock_ids)).desc("_id").limit(FEEDS_COUNT_CONTENT_STOCK_DB).to_a.sample(FEEDS_COUNT_CONTENT_STOCK)
    end

    def self.__search_events(user_id)
      return if user_id.to_i == 0
      user_ids = ::Follow::User.followed_user_ids(user_id)
      MD::Feed.events.where(:user_id.in => user_ids, :feeder_id.ne => nil, :recommend_type =>'private', :reader_ids.ne => user_id, :created_at.gt => 3.days.ago).desc(:_id).limit(FEEDS_COUNT_EVENTS_DB).to_a.sample(FEEDS_COUNT_EVENTS)
    end

    # FEED排序
    def self.generate_feeds(user, feed_hubs=[], position_stock_ids=[], following_stock_ids=[])
      return [] if feed_hubs.blank?

      feeds, hub_ids = [], []

      feed_hubs.uniq!
      feed_hubs.sort_by!{|hub| (hub.weight || rand(6)+1) * -1 }
      # feed_hubs
      feed_hubs.each do |hub| 
        if hub.is_a?(MD::FeedHub)
          hub_ids << hub.id 
          feeds << hub.push_to_feeds(user, position_stock_ids, following_stock_ids)
        else
          feeds << hub.push_to_feeds(user)
        end
      end
      MD::FeedHub.where(:_id.in=>hub_ids).add_to_set(reader_ids: user.try(:id)) if user.try(:id)
      feeds.compact
    end

    # 用户最后一条Feed，用来临时解决Android 必须获取一条新feed，才去触发最后一条feed的bug
    def self.last_feed(user)
      MD::Feed.search_feeds_for_down(user.try(:id), nil, nil, 10)
    end

    def push_to_feeds(user, position_stock_ids=[], following_stock_ids=[])
      return if user.blank? # or reader_ids.include?(user.id)
      case recommend_category.to_s
      when 'filter'
        MD::FeedRecommendFilter.publish_to_private_feed(user.id, recommend_type, feed_type)
      when 'content'
        # 如果不是 个股News，无须匹配自选股、持仓 8月24日
        return MD::Feed.add(feed_type, nil, source, user: user) unless recommend_type == 'content_news_5'

        position_stock = (position_stock_ids & (stock_ids||[])).last
        following_stock = (following_stock_ids & (stock_ids||[])).last
        if position_stock.present?
          MD::Feed::NewsPosition.add(user, source, BaseStock.find(position_stock))
        elsif following_stock.present?
          MD::Feed::NewsStock.add(user, source, BaseStock.find(following_stock))
        else
          MD::Feed.add(feed_type, nil, source, user: user)
        end
      end
    end

    # feed_type,    source_id
    # news,         asdjdsjkdsjksdj
    # topic,        12
    # article,      111
    # filter,       filter_lhb_1
    def self.add_hub(feed_type, source_id)
      case feed_type.to_s
      when 'news'
        news = MD::Data::SpiderNews.find(source_id)
        add_news(source_id, news.category_id||news.category)
      when 'topic'
        add_topic(source_id)
      when 'article'
        add_article(source_id)
      when 'filter'
        add_filter(source_id)
      end
    end

    # 将Feed事件收集到到FeedHub中
    # 按照规则来做分发和推荐
    # feed_type feed类型
    # source_id Feed SourceId
    # recommend_type推荐类型
    # source_type 指定source类型，用来处理多态问题 或者DB中不存在的对象，比如filter
    #
    # MD::FeedHub.add(:news, '55d1ca1176158f723d000257', 'content_news_1')
    # MD::FeedHub.add('filter_lhb_1')
    def self.add(feed_type, source_id, recommend_type, source_type=nil)
      return if feed_type.blank? or source_id.blank?
      source_type ||= FEED_MAPPING[feed_type.to_sym]
      feed_hub = new(feed_type: feed_type, source_type: source_type, source_id: source_id, recommend_type: recommend_type)
      feed_hub.save
    end

    # MD::FeedHub.add_news('55d1ca1176158f723d000257', '快讯')
    # recommend_type: 即 category_id
    def self.add_news(source_id, recommend_type)
      unless recommend_type =~ /^content*/
        recommend_type = MD::FeedRecommendContent::CATEGORY_MAPPING[recommend_type]
      end
      return if recommend_type.blank?
      add(:news, source_id, recommend_type)
    end

    # MD::FeedHub.add_filter('filter_lhb')
    def self.add_filter(filter_type)
      FeedRecommendFilter.generate_all(filter_type)
      MD::FeedRecommendFilter.clean_from_hub(filter_type)
    end

    # 添加单条filter
    # feed_type:  filter_lhb
    # filter_id: filter_lhb_1
    def self.add_single_filter(filter_type)
      filter_id, feed_type = filter_type.to_s.match(/(.*)_\d/).to_a
      add(feed_type.to_sym, filter_id, filter_id, 'Filter')
    end

    # MD::FeedHub.add_article(111)
    def self.add_article(source_id)
      add(:article, source_id, :content_article_1)
    end

    def self.add_topic(source_id)
      add(:topic, source_id, :content_topic_1)
    end

    ####### 冷启动
    def self.generate_all
      MD::FeedRecommendFilter.generate_all
      MD::FeedRecommendContent.generate_all
    end


    def self.clean_all_expired
      where(:expired_at.lt => Date.today).delete_all
    end


    # Feed回调，自动设置一些属性
    # title 标题
    # recommend_category 推荐种类  content, social, events
    before_validation :set_data, on: :create
    def set_data
      self.recommend_category = FeedRule.get_category(feed_type)
      self.time_rule = (feed_rule[:time_rule] rescue nil)
      self.title = get_title

      if recommend_category.to_s == 'filter'
        self.url = "#{$mobile_host}/filters/#{recommend_type.sub(/filter_/, '')}" 
        self.weight = 10
      end
      
      if content?
        # self.expired_at = Time.now + FeedRule::TimeRule::TTL_CONTENT
        if source.try(:source_class).try(:demodulize) == "Recommend"
          self.time_rule = self.feed_rule[:time_rule]
          self.weight = 9
          self.expired_at = expired_time(Time.now)
        else
          self.weight = self.feed_rule[:weight]
          self.expired_at = expired_time(source.try(:published_at) || source.created_at)
        end
        
        self.stock_ids = source.try(:stock_ids) || []
        self.pics = source.try(:pic_urls) || []
      end

    end

    def get_title
      if content?
        source.try(:title) || source.try(:name)
      else
        feed_rule[:name] rescue nil
      end
    end

    def content?
      recommend_category == "content"
    end

    def source_url
      if content?
        "#{$mobile_host}/pages/#{feed_type.to_s.pluralize}/#{source_id}"
      else
        url
      end
    end


    def edit_source_url
      if content?
        return "/admin/es/spider_news/#{source_id}/edit" if feed_type.to_s == 'news'
        "/admin#{source_url}/edit"
      else
        url
      end
    end

    # 阅读过该feed
    # 注意 该方法不会save
    # 需要手动调用 save
    # feed.read([1,2,3]).save
    def read(user_ids)
      self.reader_ids.push(*user_ids)
    end

    # MD::FeedHub.click('MD::Data:, :SpiderNews', 'someid', 1001)
    def self.click(source_type, source_id, user_id)
      return if source_type.blank? or source_id.blank? or user_id.blank?
      collection.find(source_type: source_type, source_id: source_id)
        .update_one("$inc" => { clicks_count: 1 }, "$addToSet" => {clicker_ids: user_id})
    end

    def clickers_count
      @clickers_count ||= (clicker_ids.length)
    end

    def readers_count
      @readers_count ||= (reader_ids.length)
    end

    def click_div_percent
      return '--' if readers_count <= 0
      "#{Caishuo::Utils::Helper.div_percent(clickers_count, readers_count)}%"
    end

    def feed_rule
      @feed_rule ||= case recommend_category.to_s 
      when "filter"
        MD::FeedRecommendFilter::TYPES[recommend_type.to_sym]
      when "content" 
        # MD::FeedRecommendContent::TYPES[recommend_type.to_sym]
        MD::FeedCategory.get_rule(recommend_type)
      end
    end

    def expired_time(time)
      MD::FeedRule::TTLRule.feed_expired_at(feed_rule[:ttl_rule], time)
    end

    def reset_weight(new_weight = 10)
      self.weight = new_weight
      self.time_rule = [0] if new_weight == 10
      self.delay_expired_at
      self.save
    end

    def delay_expired_at
      self.created_at = Time.now
      self.expired_at = expired_time(Time.now)
    end

    # 推荐分类名称  Filter, 热点、专栏、头条、行业板块...
    def recommend_type_name
      feed_rule[:name] rescue recommend_type
    end

    def recommend_time_name
      MD::FeedRule::TimeRule.feed_rule_name(time_rule)
    end

    def source=(obj)
      return if obj.blank?
      @source = obj
      self.source_type, self.source_id = obj.class.to_s, obj.id
    end

    def source
      @source ||= (source_type.constantize.find(source_id) rescue nil)
    end

    def deleted?
      state == STATES[:deleted]
    end

    def toggle_state!
      update(state: deleted? ? STATES[:normal] : STATES[:deleted])
    end

    def self.auto_status
      $redis.get("feeds_auto_status") || "1"
    end

    def self.auto_status_opened?
      auto_status == "1"
    end

    def self.auto_status_name
      auto_status == "1" ? "<b class='green'>已开启</b>" : "<b class='red'>已关闭</b>"
    end

    def self.toggle_auto_status
      if auto_status == "1"
        $redis.set("feeds_auto_status", "0")
      else
        $redis.set("feeds_auto_status", "1")
      end
    end

    def jpush_params
      if content?
        {mentionable_type: feed_type.to_s, mentionable_id: source_id}
      else
        {mentionable_type: "url", mentionable_id: source_url}
      end
    end

    def time_rule=(data = [])
      super data.delete_if(&:blank?).map(&:to_i)
    end

    def self.append_content_feeds(user_id, uuid, limit = 10)
      user = MD::User.find(user_id) rescue nil
      user = MD::User.new(id: uuid) if user.blank?

      content_hubs = MD::FeedHub.where(recommend_category: 'content', :recommend_type.nin => ['content_news_4', 'content_news_5'])
                     .where(:expired_at.gt => 1.days.ago, :expired_at.lt => Time.now)
                     .where(:reader_ids.ne => user.id).desc("_id").limit(limit).to_a
      feeds = generate_feeds(user, content_hubs)

      # app登录切换时，feeds流不一定重新刷新，会导致传过来的feed id不正确，所以现取min
      start_position = MD::Feed.where(user_id: user.id).min(:position)
      start_position = start_position > 0 ? 0 : start_position

      feeds.each_with_index do |feed, index|
        feed_created_at = content_hubs.select {|h| h.source_type == feed.source_type && h.source_id == feed.source_id}.first.try(:created_at)
        feed.update(position: start_position - index - 1, created_at: feed_created_at)
      end
      feeds
    end
  end
end
