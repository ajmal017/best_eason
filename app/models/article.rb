class Article < ActiveRecord::Base
  include Followable
  include Commentable
  
  mount_uploader :img, ArticleUploader

  IGNORE_IMAGES = [
    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZYpib0BuV461nibMDDyjyhcGTWCEv26yheVTYpia8Ju29gwK0kPWpNICiba4zSt9tHK163acxRrfKeKGQ/0",
    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9Zb4DejqJJabDPMK4vDssGetOia84WEm2CKxb3NBnZetzthZo0bTz3PJ1iblt9oLx3EGEI7DegfzibtHA/0",
    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9Zb5C9SYG3T0W1uyGMqJoI44UYTibrdicSVibIszBuWXj2Y7NxC6BPvG3PyrWjpH8A8ribDp0Zf8KxFm3A/0",
    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZaL1hpeYUvnOSRWnPfqWoz9Wlp6UmaWNX4LTrJ8u6RBuzxyOB2W6qZbiabNp4F3JKYDzGFtI3G2l0Q/0",
    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZbWUrLjd6Cgk7AfaoicjY46ERxUuDOmJfkQ5NRYAbwchEjcWXYsb0PFUWY72iaROCrSvFUAt3ft3Iww/0"
  ]
  
  VISIBILITIES = {
    "全部" => "",
    "是" => true,
    "否" => false
  }
  
  SYNCHRONIZED = {
    "全部" => "",
    "是" => true,
    "否" => false
  }
  
  has_many :category_articles
  has_many :categories, through: :category_articles

  has_many :article_stocks
  
  accepts_nested_attributes_for :category_articles
  
  belongs_to :author,  class_name: 'User', foreign_key: 'user_id'
  
  validates :title, uniqueness: true, :presence => {:message => "标题不能为空！"},
            :length => {:maximum => 50, :message => "长度不正确[建议长度不超过50]"}
  validates :content, :presence => {:message => "内容不能为空！"}

  scope :by_category, -> (category) { category.present? ? category.articles : self.except_pony_report }
  scope :of_public, -> { where(viewable: true) }
  scope :of_title, -> (title) { where(title: title) }
  scope :except_pony_report, -> { joins("left join category_articles on category_articles.article_id = articles.id").where("category_articles.category_id <> 6 || category_articles.category_id is NULL") }
  
  def self.fuzzy_search(options)
    self.find_by(url: options[:url]) || self.find_by(url: options[:url].gsub(/#rd$/, "")) || self.find_by(title: options[:title])
  end
  
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :temp_img_id

  before_save :set_avatar

  def set_avatar
    if temp_img_id.present?
      self.img = Upload::Article.find(temp_img_id).image.large
      self.write_img_identifier
    end
  end

  def temp_image_url
    if temp_img_id.present?
      Upload::Article.find(temp_img_id).image.url(:large)
    else
      self.img.url
    end
  end

  def intelligent_update(attrs)
    category = attrs.delete(:category)
    category.present? ? self.categories = Category.where(id: category) : self.categories.clear
    self.attributes = attrs
    self.save
  end
  
  def update_attrs(attrs)
    self.remote_img_url = attrs.delete(:remote_img_url)
    self.images = attrs.delete(:images)
    self.attributes = attrs
    self.save!
  end
  
  def toggle_viewable!
    self.update(viewable: !self.viewable)
  end
  
  def update_index_image(url)
    self.remote_img_url = url
    self.save!
  end
  
  def truncated_url
    if self.url =~ /http:\/\/mp\.weixin\.qq\.com\/s\?__biz=MzA3MzQzOTMzOQ==\&mid=(.*)/
      $1
    else
      self.url.truncate(40)
    end
  end
  
  def incr!
    
  end

  def source_info
    title
  end

  def stock_ids
    self.article_stocks.pluck(:stock_id)
  end
  
  def description
    Nokogiri::HTML(content).text.gsub("\n","").full_strip.truncate(100)
  end
  
  def parsed_content
    Nokogiri::HTML(content).search("p").reject { |x| x.search("img").first && IGNORE_IMAGES.include?(x.search("img").first["data-src"]) }
  end
  
  def self.import_related_stocks
    logger.info("INFO: 删除所有类别与文章之关联")
    CategoryArticle.delete_all
    file_path = Rails.root.join("public", "articles.xlsx").to_s
    spreadsheet = Roo::Excelx.new(file_path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      article = find_by(id: row["id"].to_i)
      if article
        article.related_stocks = row["related_stocks"].to_s.gsub("，",",")
        article.related_baskets = row["related_baskets"].to_s.gsub("，",",")
        article.viewable = row["viewable"].to_i == 1 ? false : true
        article.save!
        Category.where(id: row["category"].to_s.gsub("，",",").split(",")).each { |c| c.articles << article } if row["category"].present?
        if row["viewable"].to_i != 1 && row["category"].blank?
          c = Category.find(5)
          c.articles << article
        end
        logger.info("INFO: import article by id=#{row['id']}")
      else
        logger.info("ERROR: cannot find article by id=#{row['id']}")
      end
    end 
  end

  after_save :create_article_stocks, if: 'self.related_stocks_changed?'
  def create_article_stocks
    stock_ids = article_stocks.inject([]){|ret, as| ret << as.stock_id}.tap{|x| self.article_stocks.delete_all }
    
    return true if related_stocks.blank?

    related_stocks.split(',').each do |stock_id|
      stock_ids << stock_id.to_i
      ArticleStock.find_or_create_by(article_id: self.id, stock_id: stock_id)
    end

    clear_stock_focus_cache(stock_ids.flatten.uniq.compact)
  end

  #after_save :clear_stock_focus_cache, if: 'self.related_stocks_changed? && self.related_stocks.present?'
  def clear_stock_focus_cache(stock_ids)
    stock_ids.each do |stock_id|
      $redis.keys("views/stock:focus:#{stock_id}/*").each {|k| $redis.del(k)}
    end
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end
  
  after_create :sync_content
  def sync_content
    Resque.enqueue(Articles, self.url)  
  end

  def pic_urls
    [img_url]
  end
  
  def publish_to_feed_hub
    MD::FeedHub.add_article(id) if viewable
  end

  def show_info
    {
      title: title,
      content: content,
      modified_at: created_at
    }
  end

  include AutoSeo
  def seo_urls
    [article_path(self)].map{|s| ::Setting.host + s }
  end
end
