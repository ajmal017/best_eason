# feed种类
# filter:
# event:
# content:
# * content_news_1
# * content_topic_1
# * content_article_1
class MD::FeedCategory
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Orderable

  WEIGHT_RANGE = 0..10

  field :name
  # field :lvl, type: Integer 迁移到新的字段 weight
  field :feed_type, default: :news # feed显示类型 Feed展示模版 news, topic, article 
  field :time_rule, type: Array, default: [0] # 时间策略
  field :ttl_rule, type: Integer, default: 3 # 过期策略
  field :weight, type: Integer, default: 1
  field :recommend_category, default: :content # 推荐种类, FeedHub使用 content, event, filter
  field :category_id, type: String # 分类ID
  


  validates :name, presence: true, length: { maximum: 40, allow_blank: false }, uniqueness: true
  validates :weight, presence: true, inclusion: { in: WEIGHT_RANGE }
  validates :category_id, uniqueness: true


  orderable scope: lambda { |document| where(recommend_category: document.recommend_category, feed_type: document.feed_type) }


  def time_rule=(data=[])
    super data.delete_if(&:blank?).map(&:to_i)
  end

  before_validation :strip_attributes
  def strip_attributes
    self.name = self.name.strip
  end

  before_create :set_data
  def set_data
    self.category_id ||= get_category_id
    # self._type = 'MD::Source::SpiderNewsCategory'
  end

  # 推荐类型, FeedHub使用, 比如: filter_lhb_6, content_news_1
  def get_category_id
    [recommend_category, feed_type, position] * "_"
  end


  def time_rule_name
    time_rule.blank? ? '不推送' : MD::FeedRule::TimeRule.feed_rule_name(time_rule)
  end

  def ttl_rule_name
    MD::FeedRule::TTLRule.feed_rule_name(ttl_rule)
  end

  # 内容分类
  def self.content
    all
  end

  # 通过category_id获取rule
  def self.get_rule(category_id)
    category = where(category_id: category_id).last
    return nil if category.blank?
    {
      name: category.name,
      feed_type: category.feed_type,
      time_rule: category.time_rule,
      ttl_rule: category.ttl_rule,
      weight: category.weight,
      category: category.recommend_category
    }
  end

  # 对数据进行重置
  def self.reset_all
    ::MD::FeedRecommendContent::TYPES.each do |k, v|
      MD::FeedCategory.create(category_id: k, name: v[:name], feed_type: v[:feed_type], time_rule: v[:time_rule], ttl_rule: v[:ttl_rule], weight: v[:weight])
    end
  end



end