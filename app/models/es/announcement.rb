class ES::Announcement
  include Elasticsearch::Persistence::Model
  include ElasticsearchExt::Model
  include Staticable
  # arrtibutes
  attribute :symbol, String, mapping: { index: 'not_analyzed' }
  attribute :category, String, mapping: { index: 'not_analyzed' }
  attribute :ib_symbol, Integer, default: 0, mapping: { type: 'integer' }
  attribute :title, String, mapping: {analyzer: 'ik'}
  attribute :url, String
  attribute :views, Integer, default: 0, mapping: { type: 'integer' }
  attribute :source, String, mapping: { index: 'not_analyzed' }
  attribute :pub_date, DateTime

  validates :title, presence: true
  validates :url, presence: true

  def self.sync
    Spider::Crawler.run('hk_ex_news')
  end

  def pic_urls
    []
  end

  def data
    {title: title, source: source, modified_at: pub_date}
  end
end
