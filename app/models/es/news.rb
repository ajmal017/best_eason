class ES::News
  include Elasticsearch::Persistence::Model
  include ElasticsearchExt::Model

  # arrtibutes
  attribute :title, String, mapping: {analyzer: 'ik'}
  attribute :url, String
  attribute :views, Integer, default: 0, mapping: { type: 'integer' }
  attribute :body,  String
  attribute :source, String, mapping: { index: 'not_analyzed' }
  attribute :author, String
  attribute :pub_date, DateTime

  validates :title, presence: true
  validates :url, presence: true


  def self.load(site)

  end

  def sync
    sync_body
    save
  end

  def status
    body.blank? ? '待同步' : '已同步'
  end


  #before_create :sync_body
  def sync_body
    unless self.body.present?
      body = Spider::Crawler.new(url).body
      body = Nokogiri::HTML(body)
      encoding = body.encoding
      body = self.send(self.source.to_sym, body).to_html.encode('utf-8',encoding)
      self.body = Caishuo::Utils::Helper.strip_links(body)
    end
  end
  
  def sina(body)
    body.css("#artibody > p, #artibody img_wrapper")
  end
  
  def eastmoney(body)
    body.css("#ContentBody > p")
  end
  
  def wallstreet(body)
    body.css(".article-content > p")
  end

end
