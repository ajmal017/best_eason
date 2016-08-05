# 组合
class Basket < ActiveRecord::Base
  include Followable
  include Commentable
  include BasketCalculater
  include Feedable
  include Opinionable
  include Searchable
  include BasketSearchable

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :copy_upload_temp_picture, :is_event, :need_update_counter

  validates :user_id, presence: true
  validates :title, presence: true, if: proc {|basket| basket.completed? }
  validates :title, custom_length: { max: 40 }, if: -> { normal? && title_changed? }
  validates :title, :description, sensitive: { show_words: true }

  # alias 为了notification创建
  alias_attribute :user_id, :author_id
  alias_attribute :notify_content, :title

  default_scope { where("baskets.state <> ?", STATE[:blocked]) }
  scope :finished, -> { where(state: STATE[:normal]) }
  scope :completed_and_archived, -> { where(state: [STATE[:normal], STATE[:archive]]) }
  scope :public_finished, -> { normal.where(state: STATE[:normal], visible: true) }
  scope :not_finished, -> { where(state: [STATE[:new]]) }
  scope :not_new, -> { where("state <> ?", STATE[:new]) }
  scope :archived, -> { where("state = ?", STATE[:archive]) }
  scope :not_archived, -> { where("state <> ?", STATE[:archive]) }
  scope :recommended, -> { where(recommend: true) }
  scope :for, -> (id) { find_by(id: id) }

  scope :normal, -> { where(type: "Basket::Normal") }
  scope :normal_history, -> { where(type: "Basket::History") }
  scope :normal_and_history, -> { where(type: ["Basket::Normal", "Basket::History"]) }
  scope :custom, -> { where(type: "Basket::Custom") }
  scope :custom_history, -> { where(type: "Basket::CustomHistory") }
  scope :computable, -> { where("baskets.created_at < ?", 30.days.ago) }

  scope :us, -> { where(market: "us") }
  scope :hk, -> { where(market: "hk") }
  scope :cn, -> { where(market: "cn") }

  # 参加A股大赛50强
  scope :contest, -> { where(contest: 2) }
  scope :shipan, -> { where(contest: 3) }

  has_many :basket_stocks, -> { order("basket_stocks.id asc") }
  has_many :basket_indices
  has_one :feed_basket, as: :source
  belongs_to :author, class_name: :User, foreign_key: :author_id
  alias_method :user, :author
  has_one :latest_basket_index, -> { order(date: :desc) }, class_name: :BasketIndex
  has_one :first_basket_index,  -> { order(date: :asc) }, class_name: :BasketIndex

  accepts_nested_attributes_for :basket_stocks

  has_many :stocks, through: :basket_stocks

  # like
  has_many :likes, as: :likeable, class_name: :Like, dependent: :destroy
  has_many :likers, through: :likes, source: :liker

  # order
  has_many :orders

  # 审核记录
  has_many :basket_audits
  has_one :latest_audit, -> { order(id: :desc).limit(1) }, class_name: :BasketAudit

  belongs_to :original, class_name: :Basket, foreign_key: :original_id
  belongs_to :parent, class_name: :Basket, foreign_key: :parent_id

  # 热点标签
  has_many :taggings, as: :taggable, class_name: :Tagging, dependent: :destroy
  has_many :tags, through: :taggings

  # 调仓记录
  has_many :basket_adjustments, -> { sort_by_time.visible }, foreign_key: :original_basket_id
  has_one :latest_adjustment, -> { order(id: :desc) }, class_name: :BasketAdjustment, foreign_key: :original_basket_id

  mount_uploader :img, BasketAvatar
  # 临时图片
  has_one :temp_image, as: :resource, class_name: 'Upload::Basket', dependent: :destroy
  # TODO: contest to contest_id
  belongs_to :contest_obj, class_name: :Contest, foreign_key: :contest

  # 主题状态
  STATE = {
    # 废弃
    :blocked => -1,
    # 新建、草稿
    :new => 1,
    # 完成
    :normal => 4,
    # 归档
    :archive => 5
  }

  STATE_DESC = { "已删除" => -1, "草稿" => 1, "已完成" => 4, "已归档" => 5 }

  # 主题类型，暂时无用
  # CATEGORY = {
  #   # 趋势型
  #   :trend => 1,
  #   # 事件型
  #   :event => 2
  # }
  # CATEGORY_TITLE_MAP = {1 => "趋势型", 2 => "事件型"}

  RECOMMEND = { "全部" => "", "是" => true, "否" => false }

  CURRENCY_UNITS = { us: "$", hk: "HK$", cn: "￥" }

  CURRENCIES = { us: 'USD', hk: 'HKD', cn: 'CNY' }

  CONTESTS = { 0 => "普通无参赛", 2 => "50强大赛", 3 => "实盘大赛" }

  validate :check_basket_stocks, :check_contest_change
  before_save :set_avatar, :set_other_attrs, :set_market
  before_save :set_abbrev, if: proc {|b| b.completed? }

  after_commit :created_baskets_counter_cache, if: :need_update_counter
  before_save -> { self.need_update_counter = true }, if: -> { normal? && state_changed? && (completed? || archived? || droped?) }
  after_commit :add_feed, on: [:update], if: :feed_type

  # 5月份排行算法, contest 1第一次比赛，2为50强比赛
  def rank_score(contest = 1)
    cal_date = contest == 1 ? Date.parse("2015-05-08") : Date.parse("2015-05-22")
    compare_index = BasketIndex.get_index_by(id, cal_date) || 1000
    current_index = realtime_index || 1000
    (current_index - compare_index) * 100 / compare_index rescue 0
  end

  # 大赛回报，从Redis中取Cache
  def contest_return
    BasketRankCache.score(id.to_s)
  end

  def screenshot(timestmap = nil)
    timestmap ||= updated_at.to_i
    BasketScreenshotUploader.url(id, timestmap)
  end

  def update_stocks_step_two(basket_params)
    update(basket_params.merge(modified_at: Time.now))
  end

  def update_stocks_step_three(basket_params)
    return false if basket_params[:title].blank?
    attrs = { state: Basket::STATE[:normal], modified_at: Time.now }
    # attrs.merge!(visible: true, third_party: false) if self.author.is_company_user
    status = update(basket_params.merge(attrs))
    copy_to_history_version if status && completed? && latest_history_id.blank?
    status
  end

  def is_cn?
    market == "cn"
  end

  def is_us?
    market == "us"
  end

  def is_hk?
    market == "hk"
  end

  def normal?
    "Basket::Normal" == type
  end

  # --------- cash不在basket_stocks中
  # 股票比重对应hash
  def stock_weights
    Stock::Cash.id_weights_with(stock_weights_without_cash)
  end

  def cash_weight
    Stock::Cash.weight_with(stock_weights_without_cash)
  end

  def cash_weight_percent
    Stock::Cash.weight_with(stock_weights_without_cash) * 100
  end

  def stock_weights_without_cash
    basket_stocks.map {|x| [x.stock_id, x.weight]}.to_h
  end

  def stock_ori_weights
    Stock::Cash.id_weights_with(stock_ori_weights_without_cash)
  end

  def stock_ori_weights_without_cash
    basket_stocks.map {|x| [x.stock_id, x.ori_weight]}.to_h
  end

  def symbol_weights
    weights = basket_stocks.includes(:stock).map {|x| [x.stock.symbol, x.weight]}.to_h
    Stock::Cash.symbol_weights_with(weights)
  end

  # 股票notes对应hash，cash没有notes
  def stock_notes
    basket_stocks.map {|x| [x.stock_id, x.notes]}.to_h
  end

  def stock_adjusted_weights
    weights = basket_stocks.map {|x| [x.stock_id, x.adjusted_weight]}.to_h
    Stock::Cash.id_weights_with(weights)
  end

  # 算index时初始时的weight
  def initial_stock_weights_by_date(date)
    if self.weight_changed?(date)
      stock_weights_hash = stock_weights_by_date(date)
    else
      last_day = ClosedDay.get_work_day(date - 1, market)
      stock_weights_hash = BasketWeightLog.stock_adjusted_weights(id, last_day)
    end
    stock_weights_hash = first_day_stock_weights if stock_weights_hash.blank?
    stock_weights_hash
  end

  # 去除现金weight后重新计算比例
  def self.adjust_weights_exclude_cash(stock_weights)
    weights_exclude_cash = stock_weights.select {|id, _| id > 0}
    weights_sum = weights_exclude_cash.values.sum
    weights_exclude_cash.transform_values {|w| w / weights_sum}
  end

  def ori_stock_symbol_weights
    weights = basket_stocks.includes(:stock).map {|x| [x.stock.symbol, x.ori_weight]}.to_h
    Stock::Cash.symbol_weights_with(weights)
  end

  # 股票id: 主题股票id
  def basket_stocks_hash
    Hash[basket_stocks.map {|x| [x.stock_id, x.id]}]
  end
  #--------------------------

  def stock_notes_hash
    basket_stocks.map {|bs| [bs.stock_id, bs.notes]}.to_h
  end

  def start_date
    start_on.try(:to_date)
  end

  def start_at_workday?
    ClosedDay.is_workday?(start_date, market)
  end

  def start_before_end_trading?
    end_time = trading_time_range(start_date)[1]
    start_on && start_on <= end_time
  end

  def modified_date
    modified_at.try(:to_date) || start_date
  end

  # def category_title
  #   CATEGORY_TITLE_MAP[category]
  # end

  def latest_index
    latest_basket_index.try(:index).try(:round)
  end

  def auditing?
    basket_audits.auditing.present?
  end

  def completed?
    state == STATE[:normal]
  end

  def archived?
    state == STATE[:archive]
  end

  def draft?
    state == STATE[:new]
  end

  def droped?
    state == STATE[:blocked]
  end

  def can_deploy?
    self.completed? && !visible && !self.auditing?
  end

  def can_trade?
    market != "cn" ? true : false
  end

  def state_desc
    STATE_DESC.invert[state]
  end

  def set_auditing
    basket_audits.create if self.can_deploy?
  end

  def audit_pass!(current_admin)
    if self.auditing?
      ActiveRecord::Base.transaction do
        basket_audits.auditing.last.pass!
        update_attributes(visible: true)
      end
    end
  end

  def audit_not_pass!(unpass_reason, current_admin)
    if self.auditing?
      ActiveRecord::Base.transaction do
        basket_audits.auditing.last.not_pass!(unpass_reason)
        update_attributes(visible: false)
      end
    end
  end

  def source_info
    title
  end

  def audit_unpass?
    latest_audit.try(:not_pass?)
  end

  SEARCH_ORDER_FIELD_MAP = {
    "contest_return" => "contest_return",
    "1m_return" => "one_month_return",
    "1y_return" => "one_year_return",
    "1d_return" => "one_day_return",
    "start_date" => "start_on",
    "bullish" => "bullish_percent",
    "hot" => "hot_score",
    "modified_at" => "modified_at",
    "total_return" => "total_return",
    "adjustment_at" => "adjustment_at"
  }
  SEARCH_ORDER_RETURN_NAME_MAP = { "contest_return" => "大赛成绩", "1m_return" => "1月回报", "1y_return" => "1年回报", "1d_return" => "1日回报", "total_return" => "至今回报" }
  SEARCH_ORDER_MOBILE_RETURN_NAME_MAP = { "1m_return" => "月收益", "1y_return" => "年收益", "1d_return" => "日收益", "total_return" => "总收益" }

  # MARKET to be delete
  MARKET = { "all" => ["NASDAQ","NYSE", "SEHK", "SSE", "SZSE"], "us" => ["NASDAQ","NYSE"], "hk" => "SEHK", "a" => ["SSE", "SZSE"] }
  MARKETS = { "us" => "us", "a" => "cn", "hk" => "hk" }

  def self.search_list(search_params, page = 1)
    baskets = Basket.normal.public_finished.includes(:author).distinct("baskets.id")
    if search_params[:search_word].present?
      baskets = baskets.where("baskets.abbrev like ? or baskets.description like ?", "%#{search_params[:search_word]}%", "%#{search_params[:search_word]}%")
    end
    baskets = baskets.contest if search_params[:filter] == "contest" || search_params[:market] == "contest"
    baskets = baskets.where(market: MARKETS[search_params[:market]]) if MARKETS[search_params[:market]]
    baskets = baskets.joins("inner join taggings on taggings.taggable_type = 'Basket' and taggings.taggable_id = baskets.id").where("taggings.tag_id = ?", search_params[:tag]) if search_params[:tag].present? && search_params[:tag] != "all"
    order_field = SEARCH_ORDER_FIELD_MAP[search_params[:order]]

    if order_field.present? && order_field == "contest_return"
      contest_keys = BasketRankCache.all_members
      baskets = baskets.order("field(baskets.id,#{contest_keys * ','})") if contest_keys.present?
    elsif order_field.present? && order_field == "adjustment_at"
      baskets = baskets.joins("inner join (select original_basket_id, max(created_at) created_at from basket_adjustments group by original_basket_id) bs on bs.original_basket_id = baskets.original_id").order("bs.created_at desc")
    elsif order_field.present?
      baskets = baskets.order("#{order_field} desc")
    else
      baskets = baskets.order("baskets.id desc")
    end

    baskets = baskets.paginate(page: page || 1, per_page: search_params[:per_page] || 9)
    baskets
  end
  
  def display_tags(search_tag = nil)
    selected_tags = tags.first(3).unshift(search_tag).compact.uniq.first(3)
    selected_tags.select {|tag| tag.state == 0 }
  end

  def real_indices_with_realtime_point(begin_date, end_date = Date.today)
    indices = real_indices_for_chart_cached(begin_date, end_date)

    if begin_date <= start_date
      init_date = start_at_workday? && start_before_end_trading? ? ClosedDay.get_work_day(start_date - 1, market) : start_date
      start_ts = Time.parse("#{init_date.to_s(:db)} 00:00:00 UTC").to_i * 1000
      indices.unshift([start_ts, 1000]) if indices.select {|ts, _| ts <= start_ts}.blank?
    end

    workday = exchange_instance.prev_latest_market_date
    realtime_point = Time.parse("#{workday.to_s(:db)} 00:00:00 UTC").to_i * 1000
    if indices.select {|ts, _| ts >= realtime_point}.present?
      indices
    else
      # 实盘返回实际资金ret
      index = shipan? ? shipan_index.to_f : realtime_index
      indices.push([realtime_point, index])
    end
  end

  def real_indices_for_chart_cached(start_date, end_date = 2.days.from_now.to_date)
    latest_index_time = latest_basket_index.try(:updated_at)
    cached_indices = $cache.fetch("basket_indices_#{id}_#{start_date.to_s(:db)}_#{end_date.to_s(:db)}_#{latest_index_time.try(:to_s, :db)}", expires_in: 25.hours) do
      real_indices_for_chart(start_date, end_date)
    end
    cached_indices.present? ? cached_indices : real_indices_for_chart(start_date, end_date)
  end

  def real_indices_for_chart(start_date, end_date = Date.today)
    indices = BasketIndex.get_basket_indices(id, start_date, end_date)
    indices.map {|date_str, index| [Time.parse("#{date_str.to_s} 00:00:00 UTC").to_i * 1000, index]}
  end

  def real_index_changes_for_chart(start_date, end_date = Date.today)
    indices = BasketIndex.get_basket_indices(id, start_date, end_date)
    first_index = indices.first.try(:last)
    indices.map do |date_str, index|
      [Time.parse("#{date_str} 00:00:00 UTC").to_i * 1000, ((index - first_index) / first_index).round(4) * 100]
    end
  end

  def simulated_indices_for_chart_cached(start_date, end_date = Date.today)
    $cache.fetch("basket_simulated_indices_#{id}_#{start_date.to_s(:db)}_#{end_date.to_s(:db)}", expires_in: 1.hours) do
      simulated_indices_for_chart(start_date, end_date)
    end
  end

  def simulated_indices_for_chart(start_date, end_date = Date.today)
    tickers = ori_stock_symbol_weights
    tickers = symbol_weights if tickers.blank?
    indices = BasketIndex::Simulate.indices(tickers, start_date, end_date)
    indices.map {|date_str, index| [Time.parse("#{date_str} 00:00:00 UTC").to_i * 1000, index]}
  end

  def crop_avatar
    img.recreate_versions! if cropping?
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def same_author_baskets
    Basket.public_finished.where(author_id: author_id).where.not(id: id).limit(5)
  end

  def safe_description
    Sanitize.clean(description, SanitizeRules::BASIC)
  end

  def logo_tag
    description.match(/<img .*\/>/)[0] rescue ''
  end

  # def event?
  #   CATEGORY[:event] == self.category
  # end

  def drop!
    update_attribute(:state, STATE[:blocked]) if can_drop?
  end

  # 如果没有指数，则初始化一条
  def create_first_day_index
    if can_init_first_day_index?
      work_day = ClosedDay.get_work_day_after(start_date, get_stocks_area)
      basket_indices.create(date: work_day.strftime('%Y-%m-%d'), index: 1000)
    end
  end

  # new_record stocks无法直接获取到，故使用basket_stocks往下找
  def get_stocks_area
    basket_stocks.first.try(:stock).try(:market_area) || :us
  end

  def get_area
    stocks.first.try(:market_area) || :us
  end

  # 现在按basket只能有一个地区股票处理，如果以后支持hk、us混合，需要根据业务需求调整
  def currency_unit
    CURRENCY_UNITS.with_indifferent_access[market] || stocks.first.try(:currency_unit)
  end

  def base_currency
    CURRENCIES[market.to_sym]
  end

  def market_name
    market ? ::BaseStock::MARKET_AREA_NAMES[market.to_sym] : ""
  end

  def created_one_year_ago?
    start_date <= 1.year.ago.to_date
  end

  def created_one_month_ago?
    start_date <= 1.month.ago.to_date
  end

  def set_adjusted_weights(stock_weights_hash, low_acc_stock_weights, date)
    return false if date < Exchange::Base.by_area(market).prev_latest_market_date
    return false if basket_stocks.map(&:stock_id).sort != stock_weights_hash.keys.select {|id| id > 0}.sort

    latest_history_basket_stocks = self.try(:latest_history) ? latest_history.basket_stocks : []
    update_basket_stocks = [basket_stocks + latest_history_basket_stocks].flatten.compact.map do |basket_stock|
      BasketStock.new(
        id: basket_stock.id,
        adjusted_weight: stock_weights_hash[basket_stock.stock_id],
        weight: low_acc_stock_weights[basket_stock.stock_id]
      )
    end
    # important! : must skip before_save
    BasketStock.import(update_basket_stocks, validate: false, on_duplicate_key_update: [:weight, :adjusted_weight])
  end

  def completed_orders_count
    OrderBuy.completed.where(basket_id: id).count
  end

  def owned_by?(user_id)
    author_id == user_id
  end

  def self.has_stock(stock_id)
    public_finished.includes(:author).joins(:basket_stocks).where(basket_stocks: { stock_id: stock_id }).limit(2)
  end

  def costomized_by?(customize_user_id)
    costomized_basket(customize_user_id).present?
  end

  def costomized_basket(customize_user_id)
    Basket::Custom.where(author_id: customize_user_id, original_id: original.id).order("id desc").first
  end

  def self.custom_from(original_basket_id, stock_count_hash, user)
    original_basket = Basket.find_by_id(original_basket_id)
    custom_from_basket = original_basket.costomized_basket(user.id) || original_basket
    Basket::Custom.custom_from(user.id, custom_from_basket, stock_count_hash)
  end

  def has_positions_by?(user_id)
    Position.basket_positions_by(original.id, user_id).present?
  end

  # 持仓明细中basket买卖时，需要查到找用户定制的最新主题
  def selled_or_buyed_basket_by(user)
    return self unless user.buyed_basket?(original_id.to_s)
    user_custom_basket = costomized_basket(user.id)
    user_custom_basket.present? ? user_custom_basket : self
  end

  # 组合配置
  def position_scale
    result =
      if shipan?
        grouped_stock_infos = pt_account.stocks_infos.group_by {|x| x[:sector_name]}
        sector_percents = grouped_stock_infos.map do |sector_name, infos|
          [sector_name, infos.map {|x| x[:single_position].round(2)}.reduce(:+).round(2)]
        end.to_h
        cash_percent = (100 - (sector_percents.values.reduce(:+) || 0)).round(2)

        grouped_stock_infos["现金"] = []
        sector_percents["现金"] = cash_percent

        grouped_stock_infos.map do |sector_name, _infos|
          # 调整infos内容匹配stock接口
          {
            name: sector_name,
            scale: sector_percents[sector_name],
            color: Sector.find_color_by_zh(sector_name)
          }
        end

      else
        grouped_basket_stocks = basket_stocks.includes(:stock).group_by {|bs| bs.stock.try(:sector_code)}
        sector_percents = grouped_basket_stocks.map do |sector_code, basket_stocks|
          {
            name: Sector::MAPPING[sector_code.to_s] || "其他",
            scale: basket_stocks.map(&:weight_percent).reduce(:+),
            color: Sector::COLORS[(sector_code || -1).to_s]
          }
        end
        cash_percent = 100 - sector_percents.map {|sp| sp[:scale].to_i }.reduce(:+).to_i

        # TODO 现金颜色待定
        sector_percents << { name: "现金", scale: cash_percent, color: "#CC3333" }

        sector_percents.map {|sp| sp[:scale] = sp[:scale].to_f; sp }
      end

    result
  end

  # 某用户是否持仓该组合
  def is_position_by?(user_id)
    p = Position.find_by(user_id: user_id, instance_id: id)
    p.present? && p.trading_account.present? && p.trading_account.try(:status) == 1
  end

  # 今日涨跌 -- 目前用在持仓明细
  def change_percent
    return shipan_ret_percent if shipan?
    @change_percent ||= self.completed? ? BasketIndex::Realtime.change_percent_cached(self) : nil
  end

  def realtime_index
    return shipan_index if shipan?
    @realtime_index ||= self.completed? ? BasketIndex::Realtime.cached_index(self) : nil
  end

  def realtime_total_return
    return shipan_total_ret_percent if shipan?
    ((realtime_index - 1000) * 100 / 1000).round(2) rescue 0
  end

  # 净值
  def net_worth
    (latest_basket_index.index/1000).round(2) rescue 1
  end

  def share_text
    "我在财说发现了一个有意思的投资机会 ：#{author.try(:username)} 创建的「#{title}」组合， 创建至今回报#{total_return.try(:round, 2)}%，也来发现你的投资机会吧。"
  end

  def mobile_page_title
    "「#{title}」组合_#{author.try(:username)}_创建至今回报#{total_return.try(:round, 2)}%_财说组合"
  end

  def self.fuzzy_query(str, limit = 5)
    baskets = normal
    baskets = baskets.joins(:author).where("title like ?", "%#{str.strip}%").limit(limit)
    if baskets.count < limit
      other_baskets = baskets.joins(:author).where("CONCAT_WS('|', title, users.username) like ?", "%#{str.strip}%").limit(limit)
      baskets = [baskets + other_baskets].flatten.uniq[0..(limit - 1)]
    end

    baskets.map { |x| { basket_id: x.id, title: x.title, username: x.author.username } }
  end

  def self.related_baskets_by(stock_ids)
    Basket::Normal.public_finished.joins(:basket_stocks).where(basket_stocks: { stock_id: stock_ids })
      .uniq.sort_by {|b| b.start_on.to_s}.reverse
  end

  def adjust_logs
    BasketAdjustment.logs(original_id)
  end

  def market_index_name
    BaseStock::MARKET_INDEX_NAMES.with_indifferent_access[market]
  end

  def market_index_record
    @market_index_record ||= "Stock::#{(market || 'cn').capitalize}".safe_constantize.market_index_record
  end

  def market_indices_by_date(begin_date, end_date = Date.today)
    market_index_record.market_indices_by_date_cached(begin_date, end_date)
  end

  def market_indices_with_realtime_point(begin_date, end_date = Date.today)
    indices = market_indices_by_date(begin_date, end_date)
    workday = exchange_instance.prev_latest_market_date
    realtime_point = Time.parse("#{workday.to_s(:db)} 00:00:00 UTC").to_i * 1000
    if indices.select {|ts, _| ts == realtime_point}.present?
      indices
    else
      index_change_ratio = market_index_record.change_ratio rescue nil
      if index_change_ratio
        index = (indices.last[1] || 1000) * (1 + index_change_ratio) rescue nil
        indices.push([realtime_point, index.to_f]) if index
      end
      indices
    end
  end

  # 持仓明细使用
  def infos_for_position
    as_json(only: [:id, :title, :original_id], methods: [:currency_unit, :original_id]).merge(market: market_name).symbolize_keys
  end

  def trading_time_range(date)
    # need check workday
    Exchange::Base.by_area(market).trade_time_range(date)
  end

  def ajustment_info_zh
    adjustment_log = basket_adjustments.first.basket_adjust_logs_desc.first
    "#{adjustment_log.action_desc} #{adjustment_log.stock.c_name} #{adjustment_log.stock.symbol}"
  rescue
    nil
  end

  def ajustment_info_action
    basket_adjustments.first.basket_adjust_logs_desc.first.action
  rescue
    nil
  end

  def last_ajustment_time
    basket_adjustments.first.created_at
  rescue
    nil
  end

  # 调仓次数
  def adjust_count
    basket_adjustments.calculable.count
  end

  def adjust_start_date
    # contest ? Date.parse("2015-05-08") : start_date
    start_at_workday? && start_before_end_trading? ? ClosedDay.get_work_day(start_date - 1, market) : start_date
  end

  def exchange_instance
    @exchange_instance ||= Exchange::Base.by_area(market || :cn)
  end

  def prev_workday_weights
    prev_workday = exchange_instance.previous_workday
    BasketWeightLog.stock_adjusted_weights(id, prev_workday)
  end

  def today_selled_weights
    return {} if draft?
    his_bids = history_baskets_by(exchange_instance.today).select(:id).map(&:id)
    adjustment_ids = BasketAdjustment.calculable.where(next_basket_id: his_bids).select(:id).map(&:id)
    BasketAdjustLog.where(basket_adjustment_id: adjustment_ids).reduced.except_cash
      .select(:stock_id, :weight_from, :weight_to).group_by(&:stock_id)
      .transform_values! {|logs| logs.map(&:weight_change).map(&:abs).sum.to_d}
  end

  def now_can_sell_weights
    selled_weights = today_selled_weights
    prev_workday_weights.map do |stock_id, weight|
      adjust_weight = weight - (selled_weights[stock_id] || 0)
      adjust_weight = adjust_weight > 0 ? adjust_weight : 0
      [stock_id, adjust_weight]
    end.to_h
  end

  def stock_infos_for_edit
    stock_infos = basket_stocks.includes(:stock).map(&:basic_infos)
    if is_cn? && exchange_instance.trading?
      can_sell_weights = now_can_sell_weights
      stock_infos.map do |info|
        min_weight = info["weight"] - (can_sell_weights[info["stock_id"]] || 0)
        min_weight = min_weight >= 0.001 ? min_weight.round(3).to_f : 0
        info.merge("min_weight" => min_weight)
      end
    else
      stock_infos.map { |info| info.merge("min_weight" => 0) }
    end
  end

  # 交易日9:25后至系统处理完毕中间不能调仓
  def now_can_edit?
    return true if draft? || !exchange_instance.workday?
    start_time = exchange_instance.trade_time_range(exchange_instance.today)[0]
    previous_end_time = exchange_instance.trade_time_range(exchange_instance.previous_workday)[1]
    can_adjust = !has_pending_adjustments?(previous_end_time, start_time)
    can_adjust || (Time.now + 5.minutes < start_time)
  end

  def has_pending_adjustments?(start_time, end_time)
    history_bids = Basket.normal_history.where("created_at >= ? and created_at <= ?", start_time, end_time)
                   .where(original_id: id).select(:id).map(&:id)
    BasketAdjustment.pending.where(next_basket_id: history_bids).limit(1).present?
  end

  # --------- 大赛 -----
  # 50强A股大赛
  def contest_2?
    contest == 2
  end

  def join_contest?
    contest != 0
  end

  def shipan?
    contest == 3
  end

  def player_id
    Player.by_contest(contest).by_user(author_id).last.try(:id)
  end

  def pt_account
    @pt_account ||= Player.by_contest(contest).by_user(author_id).last.try(:trading_account)
  end

  def basket_rank
    @basket_rank ||= BasketRank.by_contest(contest).by_user(user_id).last
  end

  # one_day
  def shipan_ret
    shipan_ret_percent / 100
  end

  def shipan_ret_percent
    @shipan_ret_percent ||= lambda do
      return 0 if contest_obj.try(:finished?)
      pt_account.try(:today_total_profit_percent) || 0
    end.call
  end

  def shipan_index
    (1 + shipan_ret) * (latest_index || 1000)
  end

  def shipan_total_ret_percent
    basket_rank.realtime_total_ret || 0
  end

  def full_tags
    tags = self.tags.to_a
    tags.unshift(::Tag::Group.new(name: "A股大赛")) if self.contest_2?
    tags.unshift(::Tag::Group.new(name: "实盘大赛")) if self.shipan?
    tags
  end
  # -------

  def mini_chart_url
    BasketMiniChartScreenshotUploader.url(id) + "?#{exchange_instance.previous_workday.to_s(:db)}"
  end

  private

  def set_abbrev
    title = self.title ? [self.title, self.title.to_pinyin].join(' ') : ''
    stock_index = stocks.map { |x| [x.symbol, x.name, x.c_name, x.abbrev] }.flatten.join(' ')
    self.abbrev = [title, stock_index].join(' ').strip
  end

  # 设置图像
  def set_avatar
    if copy_upload_temp_picture.present?
      self.img = temp_image.image.larger
      write_img_identifier
    end
  end

  def set_other_attrs
    if self.state_changed? && self.completed? && start_on.blank?
      self.start_on = Time.now
    end
    if normal? && self.state_changed? && self.completed?
      self.feed_type = :basket_create
      create_first_day_index
    end
    follow_by_author
  end

  def set_market
    self.market = basket_stocks.first.stock.market_area if basket_stocks.present?
  end

  # 自己关注自己创建的
  def follow_by_author
    if !self.new_record? && self.state_changed? && self.completed? && !followed_by_user?(author_id)
      follow_by_user(author_id)
    end
  end

  def check_basket_stocks
    if self.completed? && !self.is_costomized?
      errors.add(:no_basket_stocks, "完成状态下，stocks不能为空！") if basket_stocks.blank?
    end

    if basket_stocks.present?
      weights_sum = basket_stocks.map(&:weight).reduce(:+)
      errors.add(:stock_weight, "权重不合法！") if weights_sum > 1 || weights_sum <= 0

      negative_weights = basket_stocks.map(&:weight).select { |w| w < 0 }
      errors.add(:stock_weight, "权重不能为负数！") if negative_weights.present?

      stock_ids = basket_stocks.map(&:stock_id)
      areas = BaseStock.where(id: stock_ids).map(&:market_area).uniq
      errors.add(:stock_area, "不能存在多个地区股票！") if areas.length > 1
    end
  end

  def check_contest_change
    if contest_changed? && contest && author.contest_basket.present?
      errors.add(:wrong_contest, "一个人只能有一个大赛组合！")
    end
  end

  def created_baskets_counter_cache
    Resque.enqueue(UserCounterCacheWorker, author_id, "CreatedBasket")
    self.need_update_counter = false
  end
end
