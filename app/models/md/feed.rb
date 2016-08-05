module MD

  class Feed

    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: "feeds"

    attr_accessor :source


    PER_PAGE = 50

    # Feed子类映射 
    # friend -> MD::Feed::Friend
    TYPES = {
      friend: "Friend", 
      article_comment: "Comment", 
      stock_comment: "Comment", 
      basket_comment: "Comment", 
      topic_comment: "Comment", 
      news_comment: "Comment", 
      contest_comment: "Comment", 
      trading_account: "TradingAccount",
      stock_follow: "Follow",
      basket_follow: "Follow",
      topic: "Topic",
      article: "Article",
      basket_create: "Basket",
      basket_adjust: "Basket",
      comment_like: "Like",
      news: "News",
      news_position: "NewsPosition",
      banner: ""
    }
    
    # 公用 feed_types
    EVENT_TYPES = %w(friend article_comment stock_comment basket_comment topic_comment news_comment contest_comment trading_account stock_follow)
    COMMON_TYPES = %w(friend article_comment stock_comment basket_comment topic_comment news_comment contest_comment stock_follow)
    PROFILE_TYPES = COMMON_TYPES + %w(basket_create basket_adjust comment_like basket_follow)
    MOBILE_TYPES = COMMON_TYPES + %w(topic article news news_position news_stock trading_account)
    
    
    # RECOMMEND_TYPES = {
    #   article: "content_1",
    #   topic: "content_2",
    #   news: "content_3",
    # }
    
    scope :events, ->{ where(:feed_type.in => EVENT_TYPES) }
    scope :common, ->{ where(:feed_type.in => COMMON_TYPES) }
    scope :profile, ->{ where(:feed_type.in => PROFILE_TYPES) }
    scope :mobile, -> { where(:feed_type.in => MOBILE_TYPES) }

    # 来源: web, app
    # field :source, default: "web"
    # 代表谁能看到此条feed
    belongs_to :user, index: true, class_name: "MD::User"

    # 谁产生了此条Feed
    belongs_to :feeder, index: true, class_name: "MD::User"

    # feed源对象, source, 可能为新闻、好友、动作
    # 因为source不一定是MongoDB对象
    # belongs_to :source, polymorphic: true, index: true
    field :source_type
    field :source_id
    
    field :pics, type: Array

    embeds_many :items, as: :itemized, class_name: "MD::Item"

    # 对source进行的动作，比如评论、赞、 开户、销户
    # belongs_to :refer, polymorphic: true, index: true

    # 内容
    field :feed_type
    field :display_type, type: Integer   # 显示类型,  1为置顶
    field :title
    field :content
    field :url
    field :category # 盘前 盘后 盘中 之类的
    field :weight # 默认weight 取随机，只是用来做排序使用 5-10
    # private, content_*, filter_*
    field :recommend_type, default: 'private'
    field :reader_ids, type: Array, default: []
    field :time_rule, type: Integer

    field :position, type: Integer, default: 10000



    # data[:friend_ids] = [1,2,3]
    # data[:content] = ""
    field :data, type: Hash, default: {}

    index({feed_type: 1}, {background: true})
    # db.feeds.createIndex( { "user_id": 1, "feed_type": 1, "feeder_id": 1, "created_at": -1}, { background: 1 } )
    index({user_id: 1, feed_type: 1, feeder_id: 1, created_at: -1}, {background: true}) # search_feeds_for_down
    
    # db.feeds.createIndex( { "type": 1, "feed_type": 1, "items._id": 1}, { background: 1 } )
    index({_type: 1, feed_type: 1, "items._id" => 1}, {background: true})
    # db.feeds.createIndex( { "_type": 1, "feed_type": 1}, { background: 1 } )
    index({source_id: 1, _type: 1}, {background: true})

    before_create :merge_feeds

    # ###### Begin Search for Feed

    # 向下翻页 取旧Feed
    # user_id:  必填, 用户ID
    # start_id: 可选, 起始ID(不包括本身Feed), 即Feed范围 > start_id
    # end_id:   可选, 截至ID(不包括本身Feed), 即Feed范围 < end_id
    # per_page: 每页条数
    def self.search_feeds_for_down(user_id, start_id=nil, end_id=nil, per_page=nil)
      app_search_feeds(user_id, {start_id: start_id, end_id: end_id, per_page: per_page})
    end

    def self.app_feeds_down(user_id, uuid, start_id, per_page = 10)
      start_position = self.find(start_id).position
      pretty_user_id = user_id || uuid
      feeds_search = self.mobile.includes(:feeder).desc(:position, :created_at).where(user_id: pretty_user_id, :feeder_id.ne=>pretty_user_id)

      feeds = []
      feeds = feeds + feeds_search.where(:position.gte => 0, :_id.lt => start_id).limit(per_page).to_a if start_position >= 0
      feeds = feeds + feeds_search.where(:position.lt => (start_position < 0 ? start_position : 0 )).limit(per_page-feeds.count).to_a if feeds.count < per_page
      feeds = feeds + MD::FeedHub.append_content_feeds(user_id, uuid, per_page-feeds.count) if feeds.count < per_page
      feeds
    end

    # Search for Feed
    # /api/v1/feeds.json?start_id=10&end_id=1000&per_page=50
    # opts[:start_id] 起始ID
    # opts[:end_id] 终止ID
    def self.app_search_feeds(user_id, opts={})
      feeds = mobile.__find_feeds(user_id, opts).to_a
      process_feeds(user_id, feeds)
    end

    def self.search_feeds_for(user_id, opts={})
      __find_feeds(user_id, opts)
    end

    # feeder_id、user_id使用时一般二选一, feeder_id找本人产生的，user_id找关注的人产生的
    def self.__find_feeds(user_id, opts={})
      feeds = self.includes(:feeder).desc(:position, :created_at)
      
      if opts[:feeder_id].present?
        feeds = feeds.where(:feeder_id => opts[:feeder_id], user_id: opts[:feeder_id])
      elsif user_id.present?
        feeds = feeds.where(user_id: user_id, :feeder_id.ne=>user_id)
      end

      # feeds ID范围
      feeds = feeds.where(:_id.lt => opts[:last_id]||opts[:start_id]) if opts[:last_id] or opts[:start_id]
      feeds = feeds.where(:_id.gte => opts[:end_id]) if opts[:end_id]

      feeds = feeds.limit(opts[:per_page] || PER_PAGE)
    end
    
    # 实时对feeds添加followed信息
    def self.process_feeds(user_id, feeds)
      stock_ids = feeds.map{|x| x.items.select{|i| i.type.to_s == 'stock'}.map(&:id) }.flatten
      if stock_ids.present?
        followed_sids = ::Follow::Stock.by_user(user_id).where(followable_id: stock_ids).select(:followable_id).map(&:followable_id)
        feeds.each do |feed|
          feed.items.each do |item|
            next unless item.type.to_s == 'stock'
            item.ext_data = item.ext_data.to_h.merge(followed: followed_sids.include?(item.id))
          end
        end
      end
      feeds
    end

    # ###### END Search for Feed

    # ###### Begin 操作Feed
    def self.add(feed_type, feeder, source, attrs={})
      klass = "MD::Feed::#{TYPES[feed_type.to_sym]}".constantize
      return if source.blank?
      feed = klass.new(feeder: feeder, user: attrs[:user]||feeder, source: source, feed_type: feed_type)
      feed.set_data(attrs)
      feed.save
      puts "---------------#{feed.errors}" if feed.errors.present?
      feed
    end

    # user_id 操作者ID
    # feed_id 待删除的FeedID
    def self.remove(user_id, feed_id)
      feed = MD::Feed.where(id: feed_id).last
      return false if feed.blank?# or feed.user_id != user_id 
      feed.destroy
      # feed.blocker_ids << user_id
      # feed.save
    end

    # ###### End 操作Feed


    # push给好友
    # Hot User
    # Other User
    # def push_to_subscribers
#       # 粉丝
#       return unless private?
#       friend_ids = ::Follow::User.where(followable_id: feeder_id).select(:user_id).map(&:user_id)
#       MD::Feed.create(friend_ids.map{|friend_id| self.attributes.except("_id").merge("user_id" => friend_id) })
#     end


    def source=(obj)
      return if obj.blank?
      @source = obj
      self.source_type, self.source_id = obj.class.to_s, obj.id
    end
    
    def source
      @source ||= (source_type.constantize.find(source_id) rescue nil)
    end


    def title
      super || I18n.t("feeds.#{feed_type}")
    end

    def feed_content
      content || data[:content]
    end

    def web_feed_content
      data[:html_content] || feed_content
    end

    def set_data(attrs={})
      # NotImplemented
      # raise("Implement this method in #{klass}")
    end

    def get_recommend_type
      RECOMMEND_TYPES[feed_type.to_sym]
    end


    def feed_rule
      @feed_rule ||= case feed_category_name 
      when "filter"
        MD::FeedRecommendFilter::TYPES[recommend_type.to_sym]
      when "content"
        MD::FeedCategory.get_rule(recommend_type)
        # MD::FeedRecommendContent::TYPES[recommend_type.to_sym]
      end
    end

    # 种类名称 包括 内容、Filter、事件
    def feed_category_name
      return "content" if ["article", "news", "news_position", "news_stock", "topic"].include?(feed_type.to_s)
      return "filter" if feed_type =~ /filter/
      "social"
    end

    # 推荐分类名称  Filter, 热点、专栏、头条、行业板块...
    def recommend_type_name
      feed_rule[:name] rescue recommend_type
    end

    def recommend_time_name
      MD::FeedRule::TimeRule.feed_rule_name(time_rule)
    end



    def pretty_json(opts={})
      {
        id: _id.to_s,
        source_id: source_id.try(:to_s),
        feed_type: feed_type,
        feeder: feeder.try(:pretty_json),
        title: title,
        category: category,
        content: feed_content,
        pics: pics || [],
        url: url,
        items: items.map(&:pretty_json),
        display_type: display_type,
        created_at: created_at.iso8601(3)
      }
    end
    
    def web_json
      {
        id: _id.to_s,
        feed_type: feed_type,
        content: web_feed_content,
        source_id: source_id,
        items: items.map(&:web_json),
        date: web_created_at,
      }
    end
    
    def web_created_at
      created_at.to_s(:short) + "|" + created_at.iso8601(3)
    end
    
    def private?
      recommend_type == 'private'
    end

    def readed(user_id)
      self.reader_ids.push(user_id)
      self
    end

    # 事件性Feed推送
    def push_to_feeds(user)
      return unless COMMON_TYPES.include?(feed_type.to_s)
      feed = self.dup
      feed.user_id = user.id
      feed.created_at = Time.now
      feed.weight = rand(10)+1  # 默认weight 取随机，只是用来做排序使用 5-10
      feed.recommend_type = 'copy_private'
      feed.save
      self.readed(user.id).save
      feed
    end


    def self.demo_json
      [
        # trading_account
        {
          id: '55c1db9b76158fd937000011',
          feed_type: "trading_account",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },

          title: I18n.t("feeds.trading_account"),
          content: nil,
          pics: [],
          items: [],
          created_at: Time.now.iso8601(3)
        },
        # friend
        {
          id: '55c1db9b76158fd937000010',
          feed_type: "friend",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },

          title: I18n.t("feeds.friend", num: 4),
          content: "@苏博士、@lotus.su、@杨Sir、@理想吃",
          pics: [],
          items: [],
          created_at: Time.now.iso8601(3)
        },
        # stock_follow
        {
          id: '55c1db9b76158fd937000009',
          feed_type: "stock_follow",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.stock_follow", num: 3),
          content: nil,
          pics: [],
          items: [
            {
              id: 12290,
              type: "stock",
              name: "中国核电",
              symbol: "601985.SH",
              realtime_price: 10.66,
              change_percent: -3.53,
              listed_state: 1,
              followed: true
            },
            {
              id: 10199,
              type: "stock",
              name: "中国中车",
              symbol: "601766.SH",
              realtime_price: 15.25,
              change_percent: 1.1,
              listed_state: 1,
              followed: false
            },
            {
              id: 9851,
              type: "stock",
              name: "苏宁云商",
              symbol: "002024.SZ",
              realtime_price: 13.79,
              change_percent: 0,
              listed_state: 0,
              followed: false
            }
          ],
          created_at: Time.now.iso8601(3)
        },

        # topic_comment
        {
          id: '55c1db9b76158fd937000008',
          feed_type: "topic_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.topic_comment"),
          content: "评论一次热点,先把重工业删除再说！钢铁厂水泥厂",
          pics: [],
          items: [
            {
              id: 117,
              type: "topic",
              name: "热点标题测试测试测试测试"
            }
          ],
          created_at: Time.now.iso8601(3)
        },

        # basket_comment
        {
          id: '55c1db9b76158fd937000007',
          feed_type: "basket_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.basket_comment"),
          content: "评论一次组合,先把重工业删除再说！钢铁厂水泥厂",
          pics: [],
          items: [
            {
              id: 917,
              type: "basket",
              name: "组合标题测试测试测试测试"
            }
          ],
          created_at: Time.now.iso8601(3)
        },

        # stock_comment
        {
          id: '55c1db9b76158fd937000006',
          feed_type: "stock_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.stock_comment"),
          content: "@苏博士 不错不错，继续, 我在评论这股, 以下是表情[悲伤][呆]看看, 我在评论 $苏宁云商(002024.SZ)$ , 明天涨停否😄",
          pics: [],
          items: [
            {
              id: 9851,
              type: "stock",
              name: "苏宁云商",
              symbol: "002024.SZ",
              realtime_price: 13.79,
              change_percent: 0,
              listed_state: 0,
              followed: false
            }
          ],
          created_at: Time.now.iso8601(3)
        },


        # news_comment
        {
          id: '55c1db9b76158fd937000005',
          feed_type: "news_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.news_comment"),
          content: "优衣库这个广告拍的很真实，反应人性，而且毫无广告感",
          pics: [],
          items: [
            {
              id: "55b158ff44887677fb000000",
              type: "news",
              name: "优衣库股票逆势上涨",
              source: "新浪财经"

            }
          ],
          created_at: Time.now.iso8601(3)
        },

        # article_comment
        {
          id: '55c1db9b76158fd937000005',
          feed_type: "article_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.article_comment"),
          content: "这是一条专栏的评论",
          pics: [],
          items: [
            {
              id: "560",
              type: "article",
              name: "股灾避险去打新，这样申购最赚钱"
            }
          ],
          created_at: Time.now.iso8601(3)
        },


        # contest_comment
        {
          id: '55c1db9b76158fd937000004',
          feed_type: "contest_comment",
          feeder:{
            id: 1001,
            username: "程志",
            avatar: "https://cdn.caishuo.com/static/uploads/user/avatar/1001/e2a7c217a94badea36382ed36019fd0c.jpg"
          },
          title: I18n.t("feeds.contest_comment"),
          content: "这是一条大赛评论，没有items",
          pics: [],
          items: [],
          created_at: Time.now.iso8601(3)
        },


        # 多图新闻
        {
          id: '55c1db9b76158fd937000003',
          feed_type: "news",
          feeder: nil,
          title: "多张图片的新闻Demo",
          content: nil,
          #pics: ["https://office.caishuo.com/images/pic1.jpg", "https://office.caishuo.com/images/pic2.jpg", "https://office.caishuo.com/images/pic3.jpg"],
          pics: [
            "https://cdn.caishuo.com/static/uploads/upload/recommend/image/7847/large_74e5fbd07a860b77eef6ff1b3039b79b.jpg",
            "https://cdn.caishuo.com/static/uploads/topic/img/370/large_da1eb12ebabe2ba28d0a0740deda6155.jpg",
            "https://cdn.caishuo.com/static/uploads/topic/img/284/large_f683842f483754024556c7d6534ee133.jpg"
          ],
          items: [
            {
              id: 117,
              type: "news",
              name: "多图新闻标题测试测试测试",
              source: "新浪财经",
              category: "快讯"
            }
          ],
          created_at: Time.now.iso8601(3)
        },


        # 单图新闻
        {
          id: '55c1db9b76158fd937000002',
          feed_type: "news",
          feeder: nil,
          title: "单张图片的新闻Demo",
          content: nil,
          pics: ["https://office.caishuo.com/images/pic1.jpg"],
          items: [
            {
              id: 117,
              type: "news",
              name: "单图新闻标题测试测试测试",
              source: "新浪财经",
              category: "快讯"
            }
          ],
          created_at: Time.now.iso8601(3)
        },

        # 热点
        {
          id: '55c1db9b76158fd937000001',
          feed_type: "topic",
          feeder: nil,
          title: "头条工信部启动电信业网络安全试点",
          content: nil,
          pics: ["https://cdn.caishuo.com/static/uploads/topic/img/80/large_6feee8b6a5151fa668e7140297f1ef64.jpg"],
          items: [
            {
              id: 80,
              type: "topic",
              name: "头条工信部启动电信业网络安全试点",
              tags: ["互联网+"],
              category: "头条"
            }
          ],
          created_at: Time.now.iso8601(3)
        },
        {
          id: '55c1db9b76158fd936000099',
          feed_type: "article",
          feeder: nil,
          title: "这是一个专栏的标题有大图",
          content: nil,
          pics: ["https://cdn.caishuo.com/static/uploads/topic/img/80/large_6feee8b6a5151fa668e7140297f1ef64.jpg"],
          items: [
            {
              id: 80,
              type: "topic",
              name: "这是一个专栏的标题有大图",
              tags: ["互联网+", "老钱做空"],
              category: "头条"
            }
          ],
          created_at: Time.now.iso8601(3)
        },
        {
          id: '55c1db9b76158fd931000001',
          feed_type: "filter_lhb",
          feeder: nil,
          title: "龙虎榜",
          content: nil,
          url: "https://m.caishuo.com/mobile/filters/ggzjlx_1",
          pics: [],
          items: [
            {
              id: 12290,
              type: "stock",
              name: "中国核电",
              symbol: "601985.SH",
              realtime_price: 10.66,
              change_percent: -3.53,
              listed_state: 1,
              followed: true
            },
            {
              id: 10199,
              type: "stock",
              name: "中国中车",
              symbol: "601766.SH",
              realtime_price: 15.25,
              change_percent: 1.1,
              listed_state: 1,
              followed: false
            },
            {
              id: 9851,
              type: "stock",
              name: "苏宁云商",
              symbol: "002024.SZ",
              realtime_price: 13.79,
              change_percent: 0,
              listed_state: 0,
              followed: false
            }
          ],
          created_at: Time.now.iso8601(3)
        },


      ]

    end

    #----------------------- merge --------------------------
    
    def expired_feed_ids
      data[:expired_feed_ids] || []
    end
    
    NEED_MERGE_TYPES = %w(friend basket_follow stock_follow)
    MERGE_MAX_ITEM_SIZES = {
      friend: 5, basket_follow: 5, stock_follow: 3
    }
    
    def max_merge_size
      MERGE_MAX_ITEM_SIZES[feed_type.to_sym]
    end
    
    private
    
    def merge_feeds
      return true unless NEED_MERGE_TYPES.include?(feed_type.to_s)
      last_feed = self.class.where(feeder_id: feeder_id, user_id: user_id).desc(:created_at).first
      return true unless last_feed && last_feed.feed_type == feed_type
      uniq_items = last_feed.items.reject{|i| items.map(&:id).include?(i.id) }
      return true unless uniq_items.size < max_merge_size
      
      self.items.push(uniq_items)
      self.data[:expired_feed_ids] = last_feed.expired_feed_ids.push(last_feed.id.to_s)
      self.reader_ids = last_feed.reader_ids
      last_feed.destroy
    end
    
  end

end
