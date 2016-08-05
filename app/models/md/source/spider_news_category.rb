# 读取MD::FeedCategory 
# 只读
class MD::Source::SpiderNewsCategory
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "md_feed_categories"
 
  field :name
  field :weight, as: :lvl, type: Integer
  field :category_id, as: :id, type: String
  field :recommend_category
  field :feed_type

  field :time_rule, type: Array, default: [0] # 时间策略
  field :ttl_rule, type: Integer, default: 3 # 过期策略

  default_scope ->{ where(recommend_category: 'content', feed_type: 'news') }

  attr_readonly :name, :weight, :category_id, :time_rule, :ttl_rule, :recommend_category, :feed_type



  def pretty_print
    "#{name.ljust(10, '——')} 权重: #{weight}, #{time_rule_name}, 过期: #{ttl_rule_name}"
  end

  def time_rule_name
    time_rule.blank? ? '不推送' : MD::FeedRule::TimeRule.feed_rule_name(time_rule)
  end

  def ttl_rule_name
    MD::FeedRule::TTLRule.feed_rule_name(ttl_rule)
  end

 end