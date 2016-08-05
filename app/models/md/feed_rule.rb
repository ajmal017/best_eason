module MD

  # 时间
  # 实时 - 0
  #   宏观头条
  #   行业
  #   公告
  #   研报
  #   已关注用户动作
  # 盘前 - 1 (03:00am ~ 09:15am)
  #   期指 无
  # 盘中 - 2 (09:15:am ~ 11:30am 1:00pm ~ 3:00pm)
  #   个股filter（次新开板之类的）
  #   中场休息
  #   板块资金
  #   个股资金
  # 盘后 - 3 (3:00pm ~ 3:00am)
  #   当日收益情况 (先不管)
  #   龙虎榜
  #   微信公众号
  #   炒股学堂（初级班，高级版）
  #   微博，blog，社区，热门帖子
  # 周末 - 4 (周六、周日)
  #   新闻资讯
  #   人，组合，个股
  #   炒股学堂（初级班，高级版）
  #   微博，blog，社区，热门帖子
  # 中场休息 5 (11:30am ~ 1:00pm)

  class FeedRule

    FEED_TYPES = {
      filter: FeedRecommendFilter::TYPES,  # Data Filter类
      content: FeedRecommendContent::TYPES, # 内容类
      event: {}, # 事件类
    }

    # Feed 模版规则
    LAYOUTS = MD::Feed::TYPES

    # 种类名称 包括 内容、Filter、事件
    def self.get_category(feed_type)
      feed_type = feed_type.to_s
      return "content" if ["article", "news", "news_position", "news_stock", "topic"].include?(feed_type)
      return "filter" if feed_type =~ /filter/
      "social"
    end


    # 时间策略
    # 由于一个object能对应多个time rule 所以没有使用OO
    class TimeRule < Hashie::Trash

      # id: 序号
      property :id
      # name: 时间策略名称
      property :name
      # desc: 描述
      property :desc

      RULES = {
        0 => {name: '实时', desc: "24小时"},
        1 => {name: '盘前', desc: "03:00 ~ 09:15"},
        3 => {name: '盘后', desc: "15:00 ~ 次日03:00"},
        4 => {name: '周末', desc: "周六、周日"},
        5 => {name: '中场休息', desc: "11:30 ~ 13:00"},
        6 => {name: '早盘', desc: "09:15 ~ 11:30"},
        7 => {name: '午盘', desc: "13:00 ~ 15:00"},
        8 => {name: '早盘10点后', desc: "10:00 ~ 11:30"},
      }

      # Rule Name 常量，由于使用频率非常大 特此提出一个常量
      RULE_NAMES = RULES.inject({}){|hash,rule| hash[rule[0]]=rule[1][:name]; hash}

      # 过期时间
      # 公告 一周 未做
      # 新闻 24小时
      # 研报 一周 未做
      # 已关注用户动作 三天
      TTL_CONTENT = 24 * 3600
      TTL_EVENTS = 3 * 24 * 3600

      def self.load_rules
        $feed_time_rules ||= RULES.inject({}) do |hash, rule|
          hash[rule[0]] = new(rule[1].merge(id: rule[0]))
          hash
        end
      end


      def self.all
        load_rules.values
      end
      

      # 交易日
      # 周六、周日 4
      def self.get_rule
        now = Time.now
        return [0,4] if now.saturday? or now.sunday?
        timestamp = now.seconds_since_midnight
        types = [0]
        types.push(6) if (9*3600+15*60..11*3600+30*60).include?(timestamp) # 早盘 + 盘中
        types.push(7) if (13*3600..15*3600).include?(timestamp)  # 午盘 ＋ 盘中
        types.push(8) if (10*3600..11*3600+30*60).include?(timestamp) # 早盘10点后 10:00 ~ 11:30
        types << 5  if (11*3600+30*60..13*3600).include?(timestamp)
        types << 3  if now.hour >= 15 or now.hour < 3
        types
      end


      def self.get_rule_name
        RULE_NAMES.values_at(*get_rule)
      end


      def self.feed_rule_name(rules=[])
        (RULE_NAMES.values_at(*rules) * "+") rescue nil
      end


      def name_with_desc
        "<b>#{name}</b> <span class='gray'>(#{desc})</span>"
      end


    end



    # TTL相关规则
    class TTLRule < Hashie::Trash

      include Hashie::Extensions::IgnoreUndeclared

      # id: 序号
      property :id
      # name: 过期策略名称
      property :name

      # ttl_type: TTL计算类型
      # * never     无过期，永远不过期
      # * custom    自定义时间过期, 比如第二天11:30, 需要根据调用ttl_value 指定的方法名去获取过期时间
      #             方法名定义规则为 custom_ttl_{key} 例如 :custom_ttl_1
      # * duration  指定持续间隔过期, 比如 1个月以后, 1周以后, 计算公式: Time.now + ttl_value
      property :ttl_type

      # ttl_value: 根据TTL计算类型, 计算TTL时间
      property :ttl_value

      # 过期策略
      # key: 序号
      # name: 过期策略名称
      # ttl_type: TTL计算类型
      # * never     无过期，永远不过期
      # * custom    自定义时间过期, 比如第二天11:30, 需要根据调用ttl_value 指定的方法名去获取过期时间
      #             方法名定义规则为 custom_ttl_{key} 例如 :custom_ttl_1
      # * duration  指定持续间隔过期, 比如 1个月以后, 1周以后, 计算公式: Time.now + ttl_value
      # ttl_value: 根据TTL计算类型, 计算TTL时间
      TTLS = {
        0 => {name: '无过期', ttl_type: 'never', ttl_value: 99.years.to_i},
        1 => {name: '12小时', ttl_type: 'duration', ttl_value: 12.hours.to_i},
        3 => {name: '24小时', ttl_type: 'duration', ttl_value: 1.days.to_i},
        6 => {name: '3天', ttl_type: 'duration', ttl_value: 3.days.to_i},
        10 => {name: '一周', ttl_type: 'duration', ttl_value: 7.days.to_i},
        # 20 => {name: '11:30', ttl_type: 'custom', ttl_value: :custom_ttl_20},
        # 21 => {name: '09:00', ttl_type: 'custom', ttl_value: :custom_ttl_21},
        # 22 => {name: '00:00', ttl_type: 'custom', ttl_value: :custom_ttl_22},
      }

      def self.load_rules
        $feed_ttl_rules ||= TTLS.inject({}) do |hash, rule|
          hash[rule[0]] = new(rule[1].merge(id: rule[0]))
          hash
        end
      end

      def self.all
        load_rules.values
      end

      def self.get_rule(id)
        load_rules[id]
      end

      def self.feed_rule_name(id)
        get_rule(id).try(:name)
      end

      def self.feed_expired_at(id, time)
        get_rule(id).expired_at(time)
      end

      def expired_at(time)
        case ttl_type.to_s
        when 'never'
          time + ttl_value
        when 'duration'
          time + ttl_value
        when 'custom'
          try(ttl_value, time)
        end
      end

      private

      ######## 自定义过期时间
      # 自定义过期时间 策略20
      # 下一交易日11:30
      def custom_ttl_20(time)
        seconds = time.seconds_since_midnight
        if seconds < (11 * 3600 + 30 * 60)
          time.change(hour: 11, min: 30)
        else
          time.change(hour: 11, min: 30, day: time.day + 1)
        end
      end

    end


    class WeightRule < Hashie::Trash

      property :id
      # name: 时间策略名称
      property :name
      # weight: 权重
      property :weight

      RULES = {
        1 => {name: '自动(低)'},
        2 => {name: '自动(中)'},
        3 => {name: '自动(高)'},
        6 => {name: '手动(低)'},
        7 => {name: '手动(中)'},
        8 => {name: '手动(高)'},
        10 => {name: '置顶'},
      }

      MANUAL_RULES = [6,7,8,9,10]

      def self.load_rules
        $feed_weight_rules ||= RULES.inject({}) do |hash, rule|
          hash[rule[0]] = new(rule[1].merge(id: rule[0], weight: rule[0]))
          hash
        end
      end

      def self.all
        load_rules.values
      end

      def self.get_rule(id)
        load_rules[id]
      end

      def self.feed_rule_name(id)
        get_rule(id).try(:name)
      end
 
    end



  end

end