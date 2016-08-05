class BaseStock < ActiveRecord::Base
  include Followable
  include Commentable
  include Opinionable
  class << self
    extend Forwardable
    def_delegators :exchange, :now, :market_open?, :open_time, :workday?, :trading?
  end

  # 市值2.5亿$
  MARKET_CAPITALIZATION_THRESHOLD = 250000000

  # 每日成交额(昨收盘价 * 平均每天成交量)
  DAILY_TURNOVER_THRESHOLD = 200000

  # 逼近阀值
  APPROXIMATION = 0.02

  alias :stock_id :id

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :crop_t

  validates :symbol, presence: true, uniqueness: true

  validates :data_source, presence: true, on: :update, unless: proc {|bs| bs.stock_type == STOCK_TYPE[:special]}

  scope :order_by_id, -> { order("id desc") }

  # 创建日期
  scope :created_at_day, -> (created_at_day) { where("created_at >= ? and created_at < ?", created_at_day.to_time, created_at_day.to_time + 1.days) }
  scope :searchable_stocks, -> { where(qualified: true) }

  # 各交易所个股数量
  scope :nasdaq_count, -> { where(exchange: "NASDAQ").count }
  scope :sehk_count, -> { where(exchange: "SEHK").count }
  scope :nyse_count, -> { where(exchange: "NYSE").count }

  scope :between, -> (start_id, end_id) { where(id: start_id..end_id) }
  scope :sehk, -> { where(exchange: 'SEHK') }
  scope :except_sehk, -> { where.not(exchange: 'SEHK') }
  scope :except_neeq, -> { where.not(exchange: 'NEEQ') }
  scope :except_cn, -> { where.not(type: 'Stock::Cn') }
  scope :except_x, -> { where.not("exchange in (?) and symbol like 'X%'", ['SSE', 'SZSE'])}
  scope :by_ids, -> (ids) { where(id: ids) }
  scope :by_exchange, -> (exchange_name) { where(exchange: exchange_name) }
  scope :latest, -> { where(ib_last_date: maximum(:ib_last_date)) }

  # 按照Market进行分类
  scope :us, -> { where(type: 'Stock::Us') }
  scope :hk, -> { where(type: 'Stock::Hk') }
  scope :cn, -> { where(type: 'Stock::Cn') }

  # 三板
  scope :third_board, -> { where(exchange: 'NEEQ') }

  scope :normal, -> { where(stock_type: nil) }
  scope :trading_normal, -> { where(normal: true).except_delist }
  scope :except_delist, -> { where.not(listed_state: LISTED_STATE[:delist]) }

  scope :by_symbol, ->(symbol) { where("symbol = ? or ib_symbol = ?", symbol, symbol) }

  DATASOURCES = { :all => "", :yahoo => "yahoo", :ib => "ib", :hkex => "hkex"}

  EXCH = {"all" => "", "nyse" => "NYSE", "sehk" => "SEHK", "nasdaq" => "NASDAQ"}
  EXCHANGE_AREAS = {"NYSE" => :us, "NASDAQ" => :us, "SEHK" => :hk, "SSE" => :cn, "SZSE" => :cn, "NEEQ" => :cn}
  MARKET_NAMES = {"NYSE" => "纽交所", "NASDAQ" => "纳斯达克", "SEHK" => "港交所", "SSE" => "上交所", "SZSE" => "深交所", "NEEQ" => "三板"}
  MARKET_AREA_NAMES = {:cn => "沪深", :us => "美股", :hk => "港股"}
  CURRENCY_UNITS = {usd: "$", hkd: "HK$", cny: "￥"}
  MARKET_INDEX_NAMES = {cn: "沪深300", us: "S&P 500", hk: "恒生指数"}
  MARKET_INDEXES = {"bp" => "^GSPC", "nasdq" => "^IXIC", "hs" => "^HSI", "sh" => "000001.SH", "sz" => "399001.SZ", "csi300" => "000300.SH", "gem" => "399006.SZ"}
  MARKET_INDEX_AREAS = {"bp" => "us", "nasdq" => "us", "hs" => "hk", "sh" => "cn", "sz" => "cn", "csi300" => "cn", "gem" => "cn"}

  QULIFIED = {"全部" => "", "是" => true, "否" => false}

  STOCK_TYPE = {:common => "common", :special => "special"}

  # 上市状态
  LISTED_STATE = {
    # 停牌
    :abnormal => 0,
    # 正常
    :normal => 1,
    # 退市
    :delist => 2,
    # 未上市
    :unlisted => 3
  }

  LISTED_STATE_NAMES = LISTED_STATE.values.sort.zip(["停牌", "正常", "退市", "未上市"]).to_h

  LISTED_SECTORS = {
    main_board: 1,
    sme_board: 2,
    third_board: 3,
    other_board: 4,
    large_system: 5,
    gem_board: 6
  }

  LISTED_SECTOR_NAMES = {
    1 => "主板",
    2 => "中小企业版",
    3 => "三板",
    4 => "其他",
    5 => "大宗交易系统",
    6 => "创业板"
  }

  has_many :historical_quotes, dependent: :destroy

  has_one :stock_info

  has_many :suggests

  has_many :positions

  has_one :stock_screener

  has_many :rt_quotes, dependent: :destroy

  # 专栏
  has_many :article_stocks, foreign_key: :stock_id
  has_many :articles, -> { of_public }, through: :article_stocks

  has_one :latest_adjusting_factor, -> { order(id: :desc) }, class_name: :StockAdjustingFactor

  # 行业
  has_one :stock_industry

  mount_uploader :img, BaseStockAvatar

  def self.search_by(term, limit = 5)
    where("name like ?", "%#{term}%").limit(limit)
  end

  def stock_screener
    super || StockScreener.new(base_stock_id: id)
  end

  def self.get_screenshot_key
    if market_open?
      if now - 0.5.hour > open_time
        self.screenshot_key = now.strftime('%Y%m%d%H%M')
      else
        self.screenshot_key = now.strftime("%Y%m%d%H#{Time.now.min/10}0")
      end
    else
      self.screenshot_key || self.screenshot_key = now.strftime("%Y%m%d%H#{Time.now.min/10}0")
    end
  end

  # 生成abbrev
  include GenerateAbbrev
  def origin_abbrev
    c_name.to_s
  end

  class << self
    def import_c_name(file)
      spreadsheet = open_spreadsheet(file)
      header = spreadsheet.row(1)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        bs = find_by(id: row["id"]) || find_by(symbol: row["symbol"])
        if bs
          bs.attributes = row.to_hash.slice("c_name")
          bs.save!
        else
          logger.info("ERROR: cannot find stock by id=#{row['id']} or by symbol=#{row['symbol']}")
        end
      end
    end

    def open_spreadsheet(file)
      case File.extname(file.original_filename)
      when '.csv' then Roo::CSV.new(file.path)
      when '.xls' then Roo::Excel.new(file.path)
      when '.xlsx' then Roo::Excelx.new(file.path)
      else raise "Unknown file type: #{file.original_filename}"
      end
    end

    def to_csv(options = {})
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |bs|
          csv << bs.attributes.values_at(*column_names)
        end
      end
    end

    # IB_ID可能发生变化
    def fetch_by(ib_id, symbol)
      base_stock = find_by(ib_id: ib_id) || find_by(symbol: symbol) || find_by(symbol: ib_temp_symbol(symbol))
      base_stock.try(:ib_id=, ib_id)
      base_stock.try(:symbol=, symbol)
      base_stock || find_or_initialize_by(ib_id: ib_id)
    end

    def ib_temp_symbol(symbol)
      symbol.match(/\.HK$/) ? symbol.gsub(/\.HK$/, '.OLD.HK') : symbol.concat('.OLD')
    end
  end

  def screenshot
    StockScreenshotUploader.url(id, self.class.get_screenshot_key)
  end

  def suggested_to(suggest_stock)
    suggests.create(suggest_stock_id: suggest_stock.id)
  end

  def unsuggested_to(suggest_stock)
    suggests.where(suggest_stock_id: suggest_stock.id).destroy_all
  end

  def adjust_position(user_id, before_split, after_split)
    Position.account_with(user_id).stock_with(id).each { |p| p.split(before_split, after_split) }
  end

  # for_test
  def est_shares
    get_board_lot == 1 ? 100 : get_board_lot * 10
  end

  def update_supplement_info(stock_name, ib_symbol, data_source, exchange, symbol)
    self.exchange = exchange if !exchange.blank?
    self.name = stock_name.to_s.split(" ").map{|x| x.humanize}.join(" ") if stock_name.present?
    self.ib_symbol = ib_symbol if ib_symbol.present?
    self.data_source = add_data_source(data_source) if !data_source.blank?
    self.qualified = check_qualification?
    self.symbol = symbol if symbol.present?
    self.ib_last_date = Date.today
    $monitor_crawler_logger.info("#{Date.today.to_s},#{self.symbol},#{self.ib_id}")
    self.save!
  rescue Exception => e
    $crawler_logger.error("#{self.symbol} 出错了！message: #{e.message}，backtrace: #{e.backtrace.join("\n")}")
  end

  def add_data_source(data_source)
    return data_source if current_data_source_blank?
    current_data_source_include?(data_source) ? self.data_source : add_data_source!(data_source)
  end

  def add_data_source!(data_source)
    self.data_source + ",#{data_source}"
  end

  def current_data_source_blank?
    data_source.blank?
  end

  def current_data_source_include?(data_source)
    self.data_source.split(",").include?(data_source)
  end

  def check_qualification?
    exists? && calculable_market_capitalization >= MARKET_CAPITALIZATION_THRESHOLD && calculable_average_daily_volume * realtime_price_with_usd >= DAILY_TURNOVER_THRESHOLD
  end

  def exists?
    !Redis.current.hgetall(snapshot_key).blank?
  end

  # 市值
  def calculable_market_capitalization
    market_capitalization rescue 0
  end

  # 平均每天成交量
  def calculable_average_daily_volume
    thirty_days_volume_avg rescue 0
  end

  def average_daily_volume
    thirty_days_volume_avg
  end

  def pretty_thirty_days_volume
    is_cn? ? thirty_days_volume_avg.to_i/100 : thirty_days_volume_avg
  end

  # 是否设置了股价提醒
  def exist_reminder?(user_id)
    StockReminder.where("user_id = ? and stock_id = ? and reminder_value != 0", user_id, id).present?
  end

  # 模糊查询
  # limit: default 5
  # search_all: boolean, default: false
  # show_desc: boolean, default: false
  # market: all cn hk us, default: all
  # except_neeq: default false
  def self.make_fuzzy_query(str, opts = {})
    opts.reverse_merge!({limit: 5, search_all: false, show_desc: false, market: opts[:market]||"all", except_neeq: false})
    search = opts[:search_all].present? ? self.trading_normal : searchable_stocks.trading_normal
    search = search.except_neeq if opts[:except_neeq]

    if opts[:market].present? && opts[:market] != "all"
      market_scope = opts[:market].split(",").map{|m| "Stock::#{m.capitalize}" }
      search = search.where(type: market_scope)
    end

    search = opts[:show_desc] ? search.includes(:stock_info) : search
    # search = search.select('symbol, name, c_name, id, exchange, type, chi_spelling, listed_state')

    stocks = search.where("symbol = ?", str.strip).to_a
    stocks << search.where("symbol like ?", "#{str.strip}%").limit(opts[:limit]).to_a
    stocks.uniq!
    if stocks.size < opts[:limit]
      other_stocks = search.where("CONCAT_WS('|', symbol, name, abbrev, c_name, chi_spelling) like ?", "%#{str.strip}%").limit(opts[:limit])
      stocks = [stocks + other_stocks].flatten.uniq[0..(opts[:limit]-1)]
    end
    stocks
  end

  # 模糊查询
  def self.fuzzy_query(str, opts = {})
    stocks = make_fuzzy_query(str, opts)
    stocks.map do |x|
      {
        company_name: x.com_name, symbol: x.symbol,
        stock_id: x.id, area: x.market_area,
        desc: opts[:show_desc] ? x.truncated_desc : nil
      }
    end
  end

  def self.fuzzy_query_for_api(str, opts = {})
    make_fuzzy_query(str, opts)
  end

  def self.query_by_term(str, limit = 5)
    search = trading_normal
    if str.present?
      stocks = search.select('symbol, name, c_name, id').where("symbol like ?", "#{str.strip}%").limit(limit)
    else
      stocks = search.select('symbol, name, c_name, id').limit(limit)
    end

    if stocks.count < limit
      other_stocks = search.select('symbol, name, c_name, id, exchange').where("CONCAT_WS('|', symbol, name, abbrev, c_name) like ?", "%#{str.strip}%").limit(limit)
      stocks = [stocks + other_stocks].flatten.uniq[0..(limit-1)]
    end

    stocks.map {|x| x.com_name + '(' + x.symbol + ')'}
  end

  def followed_by?(user_id)
    return false if user_id.blank?
    Follow::Stock.exists?(followable: self, user_id: user_id)
  end

  def truncated_desc
    stock_info.truncated_desc rescue ""
  end

  def truncated_com_name
    c_name.present? ? c_name.truncate(12) : name.truncate(20)
  end

  def com_name
    c_name.present? ? c_name : name
  end

  def position_com_name
    short_name.present? ? short_name : com_name
  end

  def short_com_name
    name_length = com_name.to_s.match(/\p{Han}+/) ? 4 : 8
    com_name.to_s.chars[0..(name_length-1)].join
  end

  def qualify!
    update_attribute(:qualified, check_qualification?)
  end

  def self.qualify
    us.map(&:qualify!)
    sehk.map(&:qualify!)
  end

  #------------ 从redis取实时数据 ------------
  def snapshot_key
    "realtime:" + id.to_s
  end

  def realtime_infos
    @realtime ||= $redis.hgetall(snapshot_key)
  end

  # eps 每股收益
  %w(market_capitalization pe_ratio currency date bid_sizes bid_prices offer_sizes offer_prices total_value_trade average_daily_volume total_shares non_restricted_shares five_days_volume eps).each do |m|
    define_method m do
      # $redis.hget(snapshot_key, m)
      realtime_infos[m]
    end
  end

  %w(previous_close open high low change_from_previous_close percent_change_from_previous_close pe_ratio).each do |m|
    define_method m do
      # $redis.hget(snapshot_key, m).to_s.to_d
      realtime_infos[m].to_s.to_d
    end
  end

  def high52_weeks
    price = realtime_infos["high52_weeks"].to_s.to_d
    return price if high.zero?

    [price, high].max
  end

  def low52_weeks
    price = realtime_infos["low52_weeks"].to_s.to_d
    return price if low.zero?

    [price, low].min
  end

  alias :change_percent :percent_change_from_previous_close

  def volume
    realtime_infos["volume"].to_i
  end

  # 基本货币单位
  def base_currency
    currency.downcase.to_sym rescue ''
  end

  # 实时价格
  def realtime_price
    @realtime_price ||= (realtime_infos["last"].to_d rescue 0)
  end

  # 实时价格(美元)
  def realtime_price_with_usd
    usd_rate * realtime_price
  end

  def lastest_volume
    realtime_infos["volume"]
  end

  # A股按手，其他按股数
  def pretty_lastest_volume
    is_cn? ? lastest_volume.to_i/100 : lastest_volume
  end

  def pretty_volume_unit
    is_cn? ? "手" : ""
  end

  def bid
    bid_prices.to_s.split(",").first.try(:to_f)
  end

  def bid_size
    bid_sizes.to_s.split(",").first rescue nil
  end

  def pretty_bid_size
    is_cn? ? bid_size.to_i/100 : bid_size
  end

  def ask
    offer_prices.to_s.split(",").first.try(:to_f)
  end

  def ask_size
    offer_sizes.to_s.split(",").first rescue nil
  end

  def pretty_ask_size
    is_cn? ? ask_size.to_i/100 : ask_size
  end

  def bids
    bid_prices.to_s.split(",").map(&:to_f).zip(bid_sizes.to_s.split(",").map(&:to_i))
  end

  def offers
    offer_prices.to_s.split(",").map(&:to_f).zip(offer_sizes.to_s.split(",").map(&:to_i))
  end

  def adj_market_capitalization
    market_capitalization.zero? ? "--" : market_capitalization
  end

  # 转换为中文描述
  def market_capitalization_by_c_unit
    market_capitalization.zero? ? "--" : market_capitalization.to_s.to_c_unit
  end

  # 转换为以“亿”为单位的描述
  def market_capitalization_by_c_yi_unit(has_unit = false)
    market_capitalization.zero? ? "--" : market_capitalization.to_s.to_c_yi_unit(has_unit)
  end

  def adj_pe_ratio
    pe_ratio.blank? || pe_ratio.zero? ? "--" : pe_ratio.to_f.round(2)
  end

  def adj_average_daily_volume
    average_daily_volume.present? ? average_daily_volume.try(:to_number) : ""
  end

  # 每股净资产
  def net_asset_per_share
    realtime_infos["naps"]
  end

  def trade_time_str
    realtime_infos["trade_time"]
  end

  def market_time_desc
    case market_area.to_sym
    when :us then
      "美东时间"
    else
      "北京时间"
    end
  end

  #------------------------

  # CUTOFF的每日涨跌百分比
  def adjust_change_percent
    return 0 unless local_date == cutoff_today
    self.change_percent
  end

  # 每日涨跌
  def price_changed
    return 0 unless local_date == cutoff_today
    self.change_from_previous_close
  end

  def cutoff_today
    Time.now.hour >= 9 ? Date.today : Date.yesterday
  end

  # 定时任务每天算回报率
  def cal_stock_returns(now_date = Date.today - 1)
    last_workday = ClosedDay.get_work_day(now_date, market_area)
    one_month_ago = ClosedDay.get_work_day(last_workday - 1.month, market_area)
    six_month_ago = ClosedDay.get_work_day(last_workday - 6.month, market_area)
    one_year_ago = ClosedDay.get_work_day(last_workday - 1.year, market_area)
    return_hash = { one_month_return: calculate_return(last_workday, one_month_ago),
                    six_month_return: calculate_return(last_workday, six_month_ago),
                    one_year_return: calculate_return(last_workday, one_year_ago),
                    five_day_return: calculate_return(last_workday, ClosedDay.prev_workday_of(5, market_area)) }
    update(return_hash)
  end

  def get_qualified_info
    {
      :previous_close => previous_close,
      :market_capitalization => market_capitalization,
      :average_daily_volume => average_daily_volume
    }
  end

  # 今日开盘 对比 昨日闭市的变化率
  def open_change_ratio
    return 0 if previous_close.zero?
    (open - previous_close) / previous_close rescue 0
  end

  # change_percent / 100
  def change_ratio
    if is_cn? && change_percent == -100
      0
    else
      change_percent / 100 rescue 0
    end
  end

  def get_snapshot
    Redis.current.hgetall(snapshot_key)
  end

  def source_info
    c_name || name
  end

  # ======================
  # return {"bp": {id: 1, end_timestamps: 8888888}}
  def self.market_index_infos
    market_index_stocks = BaseStock.where(symbol: MARKET_INDEXES.values)
    market_symbol_map = market_index_stocks.map do |m|
      time = Exchange::Base.by_area(m.market_area).prev_latest_market_day_end_trade_time
      utc_timestamps = time.to_i * 1000
      timestamps = utc_timestamps + time.utc_offset * 1000
      [m.symbol, { id: m.id, end_timestamps: timestamps, previous_close: m.previous_close, utc_end_timestamps: utc_timestamps }]
    end.to_h
    MARKET_INDEXES.transform_values {|symbol| market_symbol_map[symbol.to_s] || {} }
  end

  def market_index_name
    MARKET_INDEX_NAMES.with_indifferent_access[market_area]
  end

  def market_indices_for_charts(time_period)
    start_date = BasketIndex.start_date_by_time_period(time_period)
    indices = market_indices_by_date_cached(start_date)
    indices.map {|d, idx| [d, ((idx - indices[0][1]) * 100 / indices[0][1]).round(4).to_f]}
  end

  def market_indices_by_date_cached(start_date, end_date = Date.today)
    $cache.fetch("cs_market_indices:#{type}_#{start_date}_#{end_date}", expires_in: 1.hours) do
      market_indices_by_date(start_date, end_date)
    end
  end

  def market_indices_by_date(start_date, end_date = Date.today)
    indices = market_index_record.historical_indices_by(start_date, end_date)
    sorted_indices = indices.map {|date, idx| [date, idx]}.sort_by {|date, _| date}
    sorted_indices.map {|date, idx| [Time.parse("#{date} 08:00:00").to_i * 1000, idx.to_f] }
  end

  def historical_indices_by(start_date, end_date)
    historical_quote_class.stock_indices_by(id, start_date, end_date)
  end

  def self.sp500
    find_by_symbol('^gspc')
  end

  def self.hs
    find_by_symbol('^hsi')
  end

  def self.csi300
    find_by_symbol("000300.SH")
  end

  def self.sse
    find_by_symbol('000001.SH')
  end

  def self.sh
    find_by_symbol('000001.SH')
  end

  def self.sz
    find_by_symbol("399001.SZ")
  end

  def self.gem
    find_by_symbol("399006.SZ")
  end

  def self.bp
    find_by_symbol("^GSPC")
  end

  def self.nasdq
    find_by_symbol("^IXIC")
  end

  def is_index?
    symbol_array = ['000001.SH', "399001.SZ", "399006.SZ", "^GSPC", "^IXIC", "^HSI", "000300.SH"]
    symbol_array.include? symbol
  end

  def top_stocks_by_exchange(order = "desc", limit = 10)
    $cache.fetch("cs:top_stocks:#{exchange}:#{order}", expires_in: 1.minutes) do
      self.class.where(exchange: exchange).select(:id, :name, :c_name)
        .includes(:stock_screener).joins(:stock_screener)
        .where("stock_screeners.change_rate is not null and stock_screeners.change_rate > -100")
        .order("stock_screeners.change_rate #{order}").limit(limit)
    end
  end

  # ======================

  include TransformSymbol
  before_save :set_yahoo_ticker, if: Proc.new{|bs| bs.symbol_changed? || bs.ticker.blank? }
  before_save :set_xignite_symbol, if: Proc.new{|bs| bs.symbol_changed? || bs.xignite_symbol.blank? }

  # 注意返回结果要为TRUE
  before_save :set_qualified_from_listed_state, if: "self.listed_state_changed?"
  def set_qualified_from_listed_state
    self.qualified = listed_state == LISTED_STATE[:normal] ? true : false
    true
  end

  # TODO: 修改所有调用此的相关方法
  def is_sehk?
    exchange == EXCH['sehk']
  end

  def not_sehk?
    !is_sehk?
  end

  def is_us?
    is_a? Stock::Us
  end

  def is_cn?
    market == "cn"
  end

  def currency_unit
    CURRENCY_UNITS.with_indifferent_access[base_currency] || "$"
  end

  def realtime_price_with_unit
    "#{currency_unit}#{realtime_price.round(2)}"
  end

  def self.market_area_by_symbols(symbols)
    where(:symbol => symbols.first(2)).first.try(:market_area)
  end

  def market_area
    EXCHANGE_AREAS[exchange]
  end

  # redis也存有currency
  def currency_by_market
    ::MD::RS::Stock::CURRENCY_MAPPINGS[market.try(:to_sym)]
  end

  def area_and_symbol
    market_area.to_s + symbol
  end

  def market_name
    MARKET_NAMES[exchange]
  end

  def market_area_name
    MARKET_AREA_NAMES[market_area]
  end

  # 港币/美元汇率
  def usd_rate
    @usd_rate ||= Currency::Cache.transform(currency_by_market, 'usd')
  end

  # 最少购买价格，根据board_lot限制
  def min_buy_money
    get_board_lot * realtime_price
  end

  def get_board_lot
    board_lot || 1
  end

  def rt_logs
    RestClient.api.stock.rt_log(id)
  end

  def prices_in_52_weeks
    $cache.fetch("stock_52_weeks_prices_#{id}", expires_in: 2.hours) do
      RestClient.api.stock.prices(id, start_date: 52.weeks.ago.to_date, end_date: Date.today, precision: 'days')
    end
  end

  after_update :logged_ib_changed, if: Proc.new{ |b| b.ib_id_changed? }
  def logged_ib_changed
    $monitor_crawler_logger.warn("#{id} changed!!!, origin: #{ib_id_was}, new: #{ib_id}")
  end

  def est_time
    Time.now.in_time_zone('Eastern Time (US & Canada)')
  end

  def com_intro
    [stock_info.try(:description), stock_info.try(:profession)].compact.join("。 ")
  end

  def relevant_baskets
    Basket.has_stock(id)
  end

  def crop_avatar
    img.recreate_versions! if cropping?
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def integrate_status
    if trading_halt?
      "停牌"
    elsif trading_delist?
      "退市"
    elsif listed_state == BaseStock::LISTED_STATE[:unlisted]
      "未上市"
    else
      market_status
    end
  end

  def self.market_area_by_symbol(symbol)
    find_by_symbol(symbol).try(:market_area)
  end

  # for 创建组合
  # 0正常交易 1涨停 2跌停 3停牌
  def market_state
    return 3 if trading_halt?
    return 0 if !is_cn?
    return 0 if !exchange_instance.trading?
    return 1 if up_limit?
    return 2 if down_limit?
    0
  end

  def basic_infos
    as_json(
      only: [],
      methods: [:stock_id, :market_area, :symbol, :realtime_price, :change_percent,
                :currency_unit, :sector_name, :adj_market_capitalization, :adj_pe_ratio,
                :one_year_return, :truncated_com_name, :get_board_lot, :market_state]
    )
  end

  # 自选follow时需要渲染到前端的信息
  def attrs_when_follow
    score = stock_screener.try(:score).to_f
    as_json(
      only: [:id, :symbol],
      methods: [:market_area, :truncated_com_name, :adj_pe_ratio]
    ).merge!(attrs_for_following).merge!(score: score)
  end

  # 自选股实时刷新信息，没有做处理的数据，前端js做相应处理
  def attrs_for_following
    as_json(
      only: [],
      methods: [:realtime_price, :change_from_previous_close, :change_percent,
                :usd_rate, :total_value_trade, :adj_market_capitalization]
    ).merge(lastest_volume: pretty_lastest_volume)
  end

  def value_to_usd(value)
    usd_rate * value.to_f rescue 0
  end

  def request_fundamental
    OrderStatusPublisher.publish({"exchange" => self.exchange, "symbol" => self.ib_symbol || self.symbol}.to_xml(root: "requestFundamentals"))
  end

  ###############################计算价格趋势##########################################
  def trend!
    {
      ten_day_avg: _10_day_close_avg,
      three_month_volume_avg: _3_month_volume_avg,
      thirty_days_volume_avg: _30_days_volume_avg
    }
  end

  def close_price_by_date(start_date, end_date)
    historical_quote_class.by_base_stock_id(self.id).select("date, last_close").where(date: (start_date..end_date)).pluck(:date, :last_close)
  end

  def _10_day_close_avg
    (historical_quote_class.by_base_stock_id(self.id).order("date desc").limit(10).pluck(:last).map(&:to_f).sum/10).round(2)
  end

  def _30_days_volume_avg
    historical_quote_class.by_base_stock_id(self.id).select(:volume).order("date desc").limit(30).pluck(:volume).map(&:to_i).sum/30
  end

  def _3_month_volume_avg
    historical_quote_class.by_base_stock_id(self.id).select(:volume).order("date desc").limit(65).pluck(:volume).map(&:to_i).sum/65
  end

  def trend_attrs
    trend_g10 = realtime_price.to_f > ten_day_avg.to_f
    trend_l10 = !trend_g10
    trend_h52 = (high52_weeks.to_f - realtime_price.to_f).abs < realtime_price.to_f * APPROXIMATION
    trend_l52 = (realtime_price.to_f - low52_weeks.to_f).abs < realtime_price.to_f * APPROXIMATION
    {
      trend_g10: trend_g10,
      trend_l10: trend_l10,
      trend_h52: trend_h52,
      trend_l52: trend_l52,
      change_rate: change_percent.try(:to_d),
      symbol: symbol
    }
  end

  def self.import_trend(stocks)
    ImportProxy.import(
      BaseStock,
      [:ten_day_avg, :three_month_volume_avg, :thirty_days_volume_avg, :id],
      stocks,
      validate: false,
      on_duplicate_key_update: [:ten_day_avg, :three_month_volume_avg, :thirty_days_volume_avg]
    )
  end

  def update_stock_trend(trend_attrs)
    StockScreener.find_or_initialize_by(base_stock_id: id).update(trend_attrs)
  end
  ###############################计算价格趋势##########################################

  ###############################将sector与exchange数据copy至screener########################################

  def sector_to_screener!
    StockScreener.find_or_initialize_by(base_stock_id: id).update(sector_attrs)
  end

  def sector_attrs
    attrs = case self.sector
              when "Basic Materials"
                { sector_bm: true }
              when "Conglomerates"
                { sector_c: true }
              when "Consumer Goods"
                { sector_cg: true }
              when "Financial"
                { sector_f: true }
              when "Healthcare"
                { sector_h: true }
              when "Industrial Goods"
                { sector_ig: true }
              when "Services"
                { sector_s: true }
              when "Technology"
                { sector_t: true }
              when "Utilities"
                { sector_u: true }
              else
                { sector_o: true }
              end
    attrs.merge(is_sehk? ? { exchange_hk: true } : { exchange_us: true } )
  end

  ###############################将sector与exchange数据copy至screener########################################

  ######################个股搜索页###############################
  # has_many :stock_screeners

  scope :market, -> (market) { market == "hk" ? where(exchange: 'SEHK') : where.not(exchange: 'SEHK') }

  scope :date_since, -> (days) { where("date > ?", BaseStock.maximum(:created_at).to_date.prev_day(days)) }

  def self.search_list(search_params = {})
    stocks = BaseStock.trading_normal.normal.except_delist.includes(:stock_screener)
    stocks = stocks.joins(:stock_screener)
    score = search_params.delete(:score)
    stocks = stocks.where("stock_screeners.score >= ?", score.to_f) if score
    sector = search_params.delete(:sector)
    stocks = stocks.where(sector_code: sector) if sector
    market = search_params.delete(:market_region)
    stocks = stocks.send(["us", "hk", "cn"].include?(market) ? market : "cn") if market.present?
    search_params.each do |name, value|
      stocks = stocks.where(stock_screeners: { value => true }) if StockScreener.attribute_names.include?(value.to_s)
    end
    stocks
  end

  def self.import_market_value(stocks)
    ImportProxy.import(
      BaseStock,
      [:id, :market_value, :rt_price],
      stocks,
      validate: false,
      on_duplicate_key_update: [:market_value, :rt_price]
    )
  end

  def market_value_with_usd
    usd_rate * market_capitalization rescue 0
  end

  def rt_price_with_unit
    currency = Currency.usd_to_hkd == 0 ? 8 : Currency.usd_to_hkd
    num = realtime_price.try(:to_f)
    is_sehk? ? num/currency : num
  end

  ######################个股搜索页###############################


  ######################split###############################

  def split(user)
    $pms_logger.info("ExecDetails: 未调平，检测分股, #{user.id},#{self.ticker}") if Setting.pms_logger
    if can_split?(user)
      split!(user)
      unreconciled_symbol
    else
      self.ib_symbol
    end
  end

  def unreconciled_symbol
    nil
  end

  def split!(user)
    $pms_logger.info("ExecDetails: 分股, #{user.id},#{self.ticker}") if Setting.pms_logger
    self.adjust_position(user.id, ca_split.before_split, ca_split.after_split)
    #ca_split.finished!
    reconcile!(user)
  end

  def reconcile!(user)
    $pms_logger.info("Reconcile: 调平,#{user.id},#{self.ticker}") if Setting.pms_logger
    unprocessed_tws.each { |tws| tws.reconcile!(user.id) }
  end

  def ca_split
    @ca_split || ( @ca_split = CaSplit.can_split?(self) )
  end

  def can_split?(user)
    ca_split && shares_at_ratio?(user)
  end

  def shares_at_ratio?(user)
    total_shares_of(user) * factor == portfolio(user) || (total_shares_of(user) * factor + tws_shares == portfolio(user))
  end

  def factor
    (ca_split.before_split/ca_split.after_split).round(15)
  end

  def total_shares_of(user)
    Position.account_with(user.id).stock_with(self.id).allocated.sum(:shares)
  end

  def unprocessed_tws
    TwsExec.by_stock(id).unprocessed
  end

  def tws_shares
    unprocessed_tws.inject(0) { |sum, exec| exec.sell? ? sum - exec.shares.to_f : sum + exec.shares.to_f }
  end

  def portfolio(user)
    @portfolio ||= Portfolio.account_with(user.id).stock_with(self.id).sum(:position)
  end

  ######################split###############################


  def self.recommend
    {
      gfh: [gfh.count,gfh.order("market_value desc").limit(3).map(&:symbol).join("、")],
      jrg: [jrg.count,jrg.order("market_value desc").limit(3).map(&:symbol).join("、")],
      score_us: [score_us.count,score_us.order("market_value desc").limit(3).map(&:symbol).join("、")],
      score_hk: [score_hk.count,score_hk.order("market_value desc").limit(3).map(&:symbol).join("、")],
      score_cn: [score_cn.count,score_cn.order("market_value desc").limit(3).map(&:symbol).join("、")],
      revert: [revert.count,revert.order("market_value desc").limit(3).map(&:symbol).join("、")]
    }
  end

  def self.recommend_by_cache
    cache_key = "stocks_search"
    $cache.fetch(cache_key, :expires_in => 24.hours){ self.recommend }
  end

  def self.gfh
    BaseStock.trading_normal.includes(:stock_screener).normal.us.joins(:stock_screener).where(stock_screeners: { 'capitalization_dy4' => true })
  end

  def self.jrg
    BaseStock.trading_normal.includes(:stock_screener).normal.cn.joins(:stock_screener).where(sector_code: 40).where(stock_screeners: { 'style_lp' => true })
  end

  def self.score_us
    BaseStock.trading_normal.includes(:stock_screener).normal.us.joins(:stock_screener).where("stock_screeners.score >= ?", 4.0)
  end

  def self.score_hk
    BaseStock.trading_normal.includes(:stock_screener).normal.hk.joins(:stock_screener).where("stock_screeners.score >= ?", 4.0)
  end

  def self.score_cn
    BaseStock.trading_normal.includes(:stock_screener).normal.cn.joins(:stock_screener).where("stock_screeners.score >= ?", 4.0)
  end

  def self.revert
    BaseStock.trading_normal.normal.includes(:stock_screener).joins(:stock_screener).where(stock_screeners: { 'consideration_bg' => true })
  end

  def self.order_type_keys
    Stock::Cn::SZSE_ORDER_TYPES.keys | Stock::Cn::SSE_ORDER_TYPES.keys | Stock::Hk::ORDER_TYPES.keys | Stock::Us::ORDER_TYPES.keys
  end


  def log_symbol_change
    if !self.new_record? && self.changes.present?
      message = ""
      self.changes.each do |field, values|
        message += "#{field} changed from #{values[0]} to #{values[1]}; "
      end
      field = self.changes.keys.join(",")
      self.valid? ? SymbolChangeLog.log_info(self.id, field, message) : SymbolChangeLog.log_error(self.id, field, message + self.errors.messages.values.flatten.join(";"))
    end
  end

  def trading?
    Exchange::Util.get_trading_areas.include?(market_area)
  end

  # 当天交易为当天开始时间，否则前一交易日开始时间，返回当地时间
  def prev_latest_start_time
    Exchange::Base.by_area(market_area).prev_latest_market_day_start_trade_time
  end

  def prev_latest_end_time
    Exchange::Base.by_area(market_area).prev_latest_market_day_end_trade_time
  end

  # SECTOR 名称
  def sector_name
    sector_code.present? ? Sector::MAPPING[sector_code.to_s] : "其他"
  end

  def sector_color
    sector_code.present? ? Sector::COLORS[sector_code.to_s] : "#000000"
  end

  # 是否停牌
  def trading_halt?
    listed_state == LISTED_STATE[:abnormal]
  end

  # 是否退市
  def trading_delist?
    listed_state == LISTED_STATE[:delist]
  end

  # 可正常交易
  def trading_normal?
    listed_state == LISTED_STATE[:normal]
  end

  # 新股
  def trading_unlisted?
    listed_state == LISTED_STATE[:unlisted]
  end

  before_create :set_stock_type, if: "self.type.nil? && self.exchange"
  def set_stock_type
    if %w{NYSE NASDAQ}.include?(exchange)
      self.type = 'Stock::Us'
    elsif exchange.downcase == "sehk"
      self.type = 'Stock::Hk'
    end
  end

  def realtime_infos_for_publish
    self.as_json(
      only: [],
      methods: [:last, :change_from_previous_close, :percent_change_from_previous_close, :bid_prices,
                :bid_sizes, :offer_prices, :offer_sizes, :low, :high, :low52_weeks, :high52_weeks]
    ).transform_values{|v| v.to_f}.merge(id: self.id)
  end

  # 持仓明细需要的stock信息
  def infos_for_positions
    as_json(
      only: [:symbol, :market_value, :id],
      methods: [:com_name, :high52_weeks, :low52_weeks, :pe_ratio, :lastest_volume, :currency_unit, :change_from_previous_close, :change_percent, :sector_name]
    ).merge(market: market_area_name, com_name: position_com_name).symbolize_keys
  end

  def realtime_kline_data(type)
    today = exchange_instance.today
    start_date, end_date = case type
      when "day"
        then [exchange_instance.prev_latest_market_date, exchange_instance.prev_latest_market_date]
      when "week"
        then [ClosedDay.get_work_day_after(today.beginning_of_week, market_area), today]
      when "month"
        then [ClosedDay.get_work_day_after(today.beginning_of_month, market_area), today]
      end
    date_ts = (end_date.to_time.to_i + end_date.to_time.utc_offset)*1000
    {
      open: open.to_f, high: high.to_f, low: low.to_f, close: realtime_price.to_f, volume: lastest_volume.to_f,
      date: date_ts, end_date: end_date.to_s(:db), start_date: start_date.to_s(:db)
    }
  end

  def now_trading?
    exchange_instance.trading?
  end

  def market_open?
    exchange_instance.market_open?
  end

  def today_workday?
    exchange_instance.workday?
  end

  # 根据股票显示开盘情况(APP用)
  def market_status
    exchange = Exchange::Base.by_area(market_area)
    return nil if exchange.blank?
    if !exchange.workday?
      "节假日休市"
    elsif exchange.market_unopen?
      "未开盘"
    elsif exchange.market_open? && !exchange.market_close?
      "交易中"
    else
      "已收盘"
    end
  end

  def historical_quote_class
    HistoricalQuote
  end

  def profit_time_range
    exchange_instance.profit_time_range
  end

  # 股票换手率
  def turnover_rate
    #return nil unless total_shares.present? && total_value_trade.present?
    return nil unless non_restricted_shares.present? && volume.present?

    (volume.to_i.fdiv(non_restricted_shares.to_i) * 100).round(2)
  end

  # 两个日期间的回报：未考虑节假日等，需调用处自己先处理好时间
  def return_between(begin_date, end_date)
    begin_index = historical_quote_class.stock_index_by(stock_id, begin_date)
    end_index = historical_quote_class.stock_index_by(stock_id, end_date)
    return 0 unless begin_index && end_index
    ((end_index - begin_index) * 100 / begin_index).round(2) rescue 0
  end

  # 对比某一天涨了多少钱
  def price_changed_by(begin_date)
    begin_price = historical_quote_class.where(base_stock_id: id, date: ClosedDay.get_work_day(begin_date, market_area)).last.try(:last) || 0
    realtime_price - begin_price
  end

  # 港股美股股指id
  FOREIGN_INDEX_IDS = [7950, 7951, 7952, 8179]
  def foreign_index?
    FOREIGN_INDEX_IDS.include?(id)
  end

  def five_day_chart_datas
    datas = HistoricalQuote.stock_chart_datas(self)
    {symbol: symbol, unit: currency_unit, datas: datas}
  end

  def news
    if self.is_a? ::Stock::Hk
      (RestClient.api.stock.news.list(id) || []) rescue []
    elsif self.is_a? ::Stock::Cn
      data = (RestClient.api.stock.spider_news.list(id) || []) rescue []
      data.map{|d| d.merge("url" => "#{Setting.host}/mobile/pages/news/#{d['id']}") }
    else
      []
    end.map{|d| d.merge("type" => "news")}
  end

  def announcements
    if !self.is_a?(::Stock::Us)
      anns = (RestClient.api.stock.announcement.list(self.id)||[]) rescue []
      anns.map!{|ann| ann.merge("url" => "#{Setting.host}/mobile/pages/announcements/#{ann['id']}") } if self.is_a?(::Stock::Cn)
      anns
    else
      []
    end.map{|d| d.merge("type" => "announcements", "info_publ_date" => (Time.at(d["info_publ_date"]).to_s rescue nil) )}
  end

  def ext_data_for_feed
    {symbol: symbol}
  end

  # 是否为三板股票
  def third_board?
    self.exchange == "NEEQ"
  end

  # 是否高风险板块
  def listed_sector_risk_high?
    LISTED_SECTORS.values_at(:sme_board, :gem_board).include?(listed_sector)
  end

  # 板块名称
  def listed_sector_name
    LISTED_SECTOR_NAMES[listed_sector]
  end

  # 大盘盈亏
  def self.market_profit(date, market)
    mention = market.is_cn? ? HistoricalQuoteCn : HistoricalQuote

    # 计算市场大盘盈亏比例
    market_contrast_price = mention.find_by(base_stock_id: market.id, date: date).last
    ((market.realtime_price - market_contrast_price) / market_contrast_price).round(4).to_f
  end

  def page_title
    "#{com_name} #{Caishuo::Utils::Helper.pretty_number(realtime_price, 2, false)} (#{Caishuo::Utils::Helper.pretty_number(change_percent, 2, false)}%) (#{symbol})"
  end

  private
  def calculate_return(last_workday, compare_date)
    daily_indices = stock_daily_indices(compare_date)
    return 0 if daily_indices.size <= 1
    today_index = stock_index_by_date(last_workday, market_area, daily_indices)
    last_return_day_index = stock_index_by_date(compare_date, market_area, daily_indices)
    if self.realtime_price.to_f > 0 && today_index && last_return_day_index
      return ((today_index/last_return_day_index - 1) * 100).round(2)
    else
      nil
    end
  end

  def stock_daily_indices(compare_date)
    dates = (compare_date-7.day..compare_date+1.day).to_a
    dates.push(((Date.today-7)..Date.today).to_a).flatten!
    historical_quote_class.stock_indices_by_dates(self.id, dates)
  end

  def stock_index_by_date(date, market_area, daily_indices)
    work_date = ClosedDay.get_work_day(date, market_area)
    sorted_indices = daily_indices.sort_by{|date, index| date }
    return nil if sorted_indices.blank? || date.to_s(:db) < sorted_indices.first[0]
    index = daily_indices[work_date.to_s(:db)]
    retry_times = 3
    until index.present? || retry_times <= 0
      work_date = ClosedDay.get_work_day(work_date - 1, market_area)
      index = daily_indices[work_date.to_s(:db)]
      retry_times = retry_times - 1
    end
    index
  end

end
