class MD::Data::SpiderNews
  include Mongoid::Document
  include Mongoid::Timestamps
  include Staticable

  field :pic_urls, type: Array
  field :type, type: String
  field :category, type: String
  field :category_id, type: String
  field :tag_names, type: String
  field :stock_ids, type: Array
  field :stock_symbols, type: Array
  field :stock_names, type: Array
  field :title, type: String
  field :url, type: String
  field :content, type: String
  field :published_at, type: Time
  field :source, type: String
  field :source_class, type: String
  field :processer, type: String
  field :views_count, type: Integer, default: 0
  field :first_industry_codes, type: Array
  field :second_industry_codes, type: Array
  field :third_industry_codes, type: Array
  field :cs_codes, type: Array

  index({ url: 1 }, { unique: true, background: true })
  index({ title: 1 }, { unique: true, background: true })

  validates :title, uniqueness: true

  def data
    {title: title, source: source, category: category, modified_at: published_at}
  end

  def set_category
    self.category = category_name
  end

  def category_name
    MD::Source::SpiderNewsCategory.find_by(category_id: category_id).try(:name)
  end

  def publish_to_feed_hub
    # MD::Feed::News.add(self)
    MD::FeedHub.add_news(self.id, self.category_id||self.category)
  end

  def as_news_json
    as_json.with_indifferent_access
  end

  before_save :set_category
  before_save :update_stock_infos, if: :stock_ids_changed?
  after_save :save_to_es

  def update_stock_infos
    stocks = BaseStock.where(id: stock_ids)
    self.stock_names = stocks.map(&:c_name)
    self.stock_symbols = stocks.map(&:symbol)
    set_industry
  end

  def set_industry
    industries = StockIndustry.where(base_stock_id: stock_ids)
    self.first_industry_codes = industries.map(&:first_industry_code).uniq
    self.second_industry_codes = industries.map(&:second_industry_code).uniq
    self.third_industry_codes = industries.map(&:third_industry_code).uniq
    components = StockComponent.where(base_stock_id: stock_ids)
    self.cs_codes = components.map(&:cs_code).uniq
    self
  end

  def topic_stocks
    BaseStock.where(id: stock_ids)
  end

  def id
    _id.to_s
  end

  def category_id
    attributes['category_id'].to_s
  end

  def source_id
    attributes['source_id'].to_s
  end

  def as_indexed_json(options={})
    as_json(except: [:type, :views_count, :_id, :category_id, :source_id], methods: [:id, :category_id, :source_id])
  end

  def save_to_es
    if ES::SpiderNews.exists?(_id)
      ES::SpiderNews.find(_id).update_attributes(as_indexed_json)
    else
      ES::SpiderNews.create(as_indexed_json)
    end
  rescue
    nil
  end
end
