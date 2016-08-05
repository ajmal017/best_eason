class ES::SpiderNews
  include Elasticsearch::Persistence::Model
  include ElasticsearchExt::Model

  # arrtibutes
  attribute :pic_urls, Array, mapping: { index: 'not_analyzed' }
  attribute :source, String, mapping: { index: 'not_analyzed' }
  attribute :category, String, mapping: { index: 'not_analyzed' }
  attribute :category_id, String, mapping: { index: 'not_analyzed' }
  attribute :tag_names, String, mapping: {analyzer: 'standard'}
  attribute :stock_ids, Array
  attribute :stock_symbols, Array
  attribute :stock_names, Array
  attribute :title, String#, mapping: {analyzer: 'mmseg_maxword'}
  attribute :url, String, mapping: {index: 'not_analyzed'}
  attribute :content, String#, mapping: {analyzer: 'mmseg_maxword'}
  attribute :source_class, String, mapping: { index: 'not_analyzed' }
  attribute :published_at, Time, mapping: { index: 'not_analyzed' }
  attribute :created_at, Time, mapping: { index: 'not_analyzed' }
  attribute :striped_content, String
  attribute :first_industry_codes, Array
  attribute :second_industry_codes, Array
  attribute :third_industry_codes, Array
  attribute :cs_codes, Array
  attribute :processer, String

  validates :title, presence: true
  validates :url, presence: true

  def styled_pic_urls(w,h=0,pattern=0)
    pic_urls.map do |pic_url|
      pic_url+"_#{w}_#{h}_.gif"
    end
  end

  def self.styled_pic_url(pic_url,w,h=0,pattern=0)
    pic_url+"_#{w}_#{h}_#{pattern}.gif"
  end

  def category_name
    MD::Source::SpiderNewsCategory.where(id: category_id).first.try(:name)
  end

  def industries
    StockIndustry.where(base_stock_id: stock_ids)
  end

  def industry_names
    industries.map(&:second_industry_name).uniq
  end

  def components
    StockComponent.where(base_stock_id: stock_ids)
  end

  def component_names
    components.map(&:name).uniq
  end

  def self.source_trans(cate)
    MD::Source::SpiderNewsSource.where(id: cate).first.try(:name)
  end

  def self.cate_trans(cate)
    MD::Source::SpiderNewsCategory.where(category_id: cate).first.try(:name)
  end
end