class TopicNews < ActiveRecord::Base
  validates :title, :url, :source, :topic_id, presence: true

  belongs_to :topic

  after_create :update_topic_modified_at
  after_update :update_topic_modified_at, if: -> { self.title_changed? }

  DOMAIN_NAMES = {
    "sina.com.cn" => "新浪", "eastmoney.com" => "东财", "18.com.cn" => "东财", 
    "xueqiu.com" => "雪球", "wallstreetcn.com" => "华尔街见闻", "qq.com" => "腾讯",
    "sohu.com" => "搜狐", "163.com" => "网易", "stockstar.com" => "证券之星", "cnfol.com" => "中金在线",
    "hexun.com" => "和讯", "jrj.com.cn" => "金融界", "ifeng.com" => "凤凰", "huanqiu.com" => "环球",
    "xinhuanet.com" => "新华"
  }

  def initialize(options)
    super(options)
    self.title = get_title
    self.source = get_source
    self.pub_time = Time.now
  end

  private

  def get_title
    NewsCrawler.crawl(self.url) || "抓取出错"
  end

  def get_source
    host = get_host
    return nil if host.blank?
    DOMAIN_NAMES.each do |domain, name|
      return name if Regexp.new("#{domain}$").match(host)
    end
    host
  end

  def get_host
    URI.parse(self.url).host
  end

  def update_topic_modified_at
    self.topic.update(modified_at: Time.now)
  end
end
