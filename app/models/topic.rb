class Topic < ActiveRecord::Base
  include Followable
  include Commentable
  
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  
  alias_attribute :user_id, :author_id

  TEMPLATES = {"a" => "普通", "b" => "大图"}
  MARKETS = {"cn" => "沪深", "hk" => "港股", "us" => "美股"}
  ADMIN_PER_PAGE = 50

  validates :title, :market, :notes, :author_id, presence: true
  validates :title, custom_length: {max: 10, message: "长度不合法"}, uniqueness: {message: "topic名称不能重复"}

  scope :sort, -> { order(position: :asc, created_at: :desc) }
  scope :sort_by_modified_at, -> { order(position: :asc, modified_at: :desc) }
  scope :visible, -> { where(visible: true) }
  scope :big_pic, -> { where(template: "b") }
  
  belongs_to :author, class_name: "Admin::Staffer", foreign_key: :author_id
  belongs_to :basket
  has_many :topic_news, -> { order(position: :asc, id: :asc) }
  has_many :topic_stocks, -> { order(position: :asc, id: :asc) }, dependent: :destroy
  has_many :stocks, through: :topic_stocks, source: :base_stock
  has_many :topic_baskets, dependent: :destroy
  has_many :related_baskets, through: :topic_baskets, source: :basket
  has_many :topic_articles, ->{ order(:position, :id)}
  has_many :articles, through: :topic_articles, source: :article
  # basket_ids 存储着basket original_id

  belongs_to :tag, class_name: 'Tag::Common', foreign_key: :tag_id

  has_one :temp_image, as: :resource, class_name: 'Upload::Topic', dependent: :destroy
  has_one :temp_big_image, as: :resource, class_name: 'Upload::TopicBigImage', dependent: :destroy

  mount_uploader :img, TopicAvatar
  mount_uploader :big_img, TopicBigImageUploader

  before_create :create_tag_common
  before_save :update_tag_name

  before_create :update_modified_at
  before_update :update_modified_at, if: :need_update_modified_at?

  def full_title
    [title, sub_title].compact.join("--")
  end

  def safe_description
    Sanitize.clean(self.notes, SanitizeRules::BASIC)
  end

  def market_desc
    BaseStock::MARKET_AREA_NAMES[self.market.to_sym]
  end

  def safe_template
    TEMPLATES.keys.include?(self.template) ? self.template : TEMPLATES.keys.first
  end

  def selected_topic_baskets
    ids = Basket.where(id: self.basket_ids.to_s.split(",")).map(&:newest_version)[0..3].map(&:id)
    Basket.where(id: ids).includes(:author)
  end

  def selected_basket_ids
    self.basket_ids.to_s.split(",").map(&:to_i)
  end

  def self.baskets_from_pool(topic_id)
    stock_ids = TopicStock.where(topic_id: topic_id).pluck(:base_stock_id).uniq
    fixed_stock_ids = TopicStock.fixed.select(:base_stock_id).where(topic_id: topic_id)
    BasketStock.select("basket_id, count(*) as total_count, count(fixed_stock_ids.base_stock_id) fixed_total").where(stock_id: stock_ids)\
                 .where("weight >= 0.1").where(baskets: {type: "Basket::Normal", state: Basket::STATE[:normal], visible: true}).joins(:basket)\
                 .joins("left join (#{fixed_stock_ids.to_sql}) fixed_stock_ids on fixed_stock_ids.base_stock_id = basket_stocks.stock_id")\
                 .group(:basket_id).having("total_count > 1 and fixed_total >= 1").order("fixed_total desc").includes(basket: [:author])
  end

  def update_related_baskets
    old_related_basket_ids = self.related_basket_ids
    new_related_basket_ids = Topic.baskets_from_pool(self.id).map(&:basket_id)
    self.topic_baskets.where(basket_id: (old_related_basket_ids - new_related_basket_ids)).destroy_all
    self.related_basket_ids = new_related_basket_ids
    self.update(baskets_count: (new_related_basket_ids + selected_basket_ids).uniq.count)
  end

  def update_float_pool
    self.stock_ids =  self.stock_ids + Topic.pending_float_stock_pool(id).map(&:stock_id)
  end

  def update_hot_score
    stock_ids = TopicStock.where(topic_id: id).pluck(:base_stock_id).uniq
    basket_ids = TopicBasket.where(topic_id: id).pluck(:basket_id).uniq
    return [] if stock_ids.blank? or basket_ids.blank?
    total_counts = Hash[BasketStock.where(basket_id: basket_ids, stock_id: stock_ids)\
                .select("stock_id, count(*) as total_count")\
                .group(:stock_id).map{|x| [x.stock_id, x.total_count]}]

    imports = topic_stocks.map do |x|
      if x.hot_score != total_counts[x.base_stock_id]
        [x.topic_id, x.base_stock_id, total_counts[x.base_stock_id]||0, x.hot_score]
      end
    end


    # imports = basket_stocks.map do |x|
    #   if x.total_count == old_topic_stocks[x.stock_id]
    #     [id, x.stock_id, old_topic_stocks[x.stock_id], old_last_topic_stocks[x.stock_id]]
    #   else
    #     [id, x.stock_id, x.total_count, old_topic_stocks[x.stock_id]]
    #   end
    # end
    TopicStock.import(
      [:topic_id, :base_stock_id, :hot_score, :last_hot_score], 
      imports.compact, 
      validate: false, 
      on_duplicate_key_update: [:hot_score, :last_hot_score]
    )
  end

  def clean_float_pool
    topic_stocks.float.delete_all
  end

  # 浮动股票池
  # 从组合中筛选股票进入股票池, 需要满足一下条件
  # 两个组合共有某只股票，且这只股票不在固定股票池中
  def self.pending_float_stock_pool(topic_id)
    stock_ids = TopicStock.where(topic_id: topic_id).pluck(:base_stock_id).uniq
    basket_ids = BasketStock.where(stock_id: stock_ids).where(stock_id: stock_ids).where("weight >= 0.1")\
                .where(baskets: {type: "Basket::Normal", state: Basket::STATE[:normal], visible: true}).joins(:basket).pluck("basket_id")
    BasketStock.where(basket_id: basket_ids).where.not(stock_id: stock_ids)\
                .select("stock_id, count(*) as total_count, avg(weight) as avg_weight, group_concat(basket_id) as basket_ids")\
                .group(:stock_id).having("total_count > 1").includes(:stock).order("total_count desc")
  end

  def activest_users
    basket_scores = topic_baskets.joins(:basket).select("baskets.author_id, count(*) as count")
                      .group("baskets.author_id").map{|tb| [tb.author_id, tb.count*10]}.to_h
    comment_ids = comments.select(&:id).map(&:id)
    comment_scores = Comment.where("id in (?) or (commentable_id in (?) and commentable_type='Comment')", comment_ids, comment_ids)
                       .group(:user_id).select("user_id, count(1) comments_count")
                       .map{|c| [c.user_id, c.comments_count]}.to_h
    comment_scores.map{|uid, score| basket_scores[uid] = basket_scores[uid] ? basket_scores[uid]+score : score }
    uids = basket_scores.sort_by{|uid, score| score}.reverse.first(10).map(&:first)
    User.where(id: uids)
  end

  def need_big_pic?
    template == "b"
  end

  def top_stocks
    self.topic_stocks.order(hot_score: :desc).limit(10)
  end

  def crop_temp_image(crop_attrs)
    self.temp_image.update(crop_attrs)
    self.temp_image.save!
    self.img = self.temp_image.image.larger
    self.write_img_identifier
    self.save
  end

  def crop_temp_big_image(crop_attrs)
    self.temp_big_image.update(crop_attrs)
    self.temp_big_image.save!
    self.big_img = self.temp_big_image.image.large
    self.write_img_identifier
    self.save
  end
  
  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  # 没有校验，只供admin后台功能调用
  def self.update_positions(class_name, ids)
    attrs_arr = []
    ids.each_with_index do |id, index|
      attrs_arr << [id.to_i, index + 1]
    end
    ImportProxy.import(class_name, %w(id position), attrs_arr, validate: false, on_duplicate_key_update: [:position])
  end

  def chart_datas
    if self.basket
      begin_date = 1.month.ago.to_date
      basket_indices = self.basket.created_one_month_ago? ? 
                            self.basket.real_indices_for_chart_cached(begin_date)
                            : self.basket.simulated_indices_for_chart_cached(begin_date)
    else
      basket_indices = 30.downto(1).to_a.map{|i| [i.days.ago.to_i*1000, 0]}
    end
    compare_value = basket_indices[0][1].to_f
    basket_indices.map{|ts, idx| [ts, ((idx-compare_value)*100/compare_value).round(2)]}
  end

  def source_info
    sub_title
  end

  def update_leading_stocks_count
    self.update(leading_stocks_count: self.topic_stocks.visible.count)
  end

  def self.grouped_stocks_by(topic_ids)
    topic_stocks = TopicStock.visible.where(topic_id: topic_ids)
                    .order(position: :asc, id: :asc)
                    .select(:id, :topic_id, :base_stock_id, :position).group_by{|ts| ts.topic_id}
                    .map{|topic_id, items| [topic_id, items.first(4).map(&:base_stock_id)]}
    stocks = BaseStock.select(:id, :name, :c_name, :symbol, :five_day_return).where(id: topic_stocks.map{|x| x[1]}.flatten)
    topic_stocks.map{|topic_id, sids| [topic_id, sids.map{|sid| stocks.select{|x| x.id==sid}.first}]}.to_h
  end

  def articles_by_stock(limit = nil)
    stock_ids = topic_stocks.fixed.select(:base_stock_id).map(&:base_stock_id)
    article_ids = ArticleStock.where(stock_id: stock_ids).select("distinct article_id").map(&:article_id)
    Article.of_public.where(id: article_ids).order(id: :desc).limit(limit)
  end

  def reset_articles
    self.articles = articles_by_stock
  end

  def pic_urls
    [img_url]
  end
  # Feed 来源: 财说
  def source
    "财说"
  end

  def category
    title
  end
  
  def publish_to_feed_hub
    MD::FeedHub.add_topic(id) if visible
  end

  def show_info
    {
      title: sub_title,
      content: notes,
      modified_at: modified_at
    }
  end

  private

  def create_tag_common
    tag = ::Tag::Common.find_or_create_by(name: self.title.strip)
    self.tag_id = tag.id
  end

  def update_tag_name
    if !self.new_record? && self.title_changed? && self.title.strip.present? && self.tag
      self.tag.update(name: self.title.strip)
    end
  end

  def update_modified_at
    self.modified_at = Time.now
  end

  def need_update_modified_at?
    need_update = false

    %w[title notes basket_ids sub_title summary].each{|col| need_update = true if self.send("#{col}_changed?") }

    need_update
  end

end
