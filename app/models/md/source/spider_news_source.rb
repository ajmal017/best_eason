class MD::Source::SpiderNewsSource
  STATUS_NAME = {
    ready: '就绪',
    running: '运行中',
    stopped: '已停止'
  }

  include Mongoid::Document
  include Mongoid::Enum
  include Mongoid::Timestamps

  field :name
  field :source_name
  field :crawler_name
  field :category_id, type: String
  field :list_page_url
  field :interval_time, default: ->{ default_interval }
  field :auto_adjust, type: Boolean, default: true
  field :last_run_at, type: Time
  field :status, type: Integer

  enum :status, [:ready, :running, :stopped], default: :ready

  belongs_to :category, class_name: "::MD::Source::SpiderNewsCategory", primary_key: :category_id

  validates :list_page_url, length: { maximum: 255, allow_blank: false }, presence: true, if: ->(){ crawler_name == "Spider::News::RecommendList" }
  validates :name, presence: true, length: { maximum: 20, allow_blank: false }, uniqueness: true
  validates :crawler_name, presence: true
  validates :category_id, presence: true

  after_destroy :check_news_exist

  def status_name
    STATUS_NAME[status]
  end

  def category_name
    category.try(:name)
  end

  def self.interval_lvls
    # 10分钟 30分钟 1小时 2小时 6小时 12小时
    [10, 30, 60, 2*60, 6*60, 12*60]
  end

  def default_interval
    60
  end

  def soft_destroy
    crawler_name == "Spider::News::Recommend" ? destroy : stop!
  end

  def check_news_exist
    !MD::Data::SpiderNews.where(source_id: id).exists?
  end
end