# A股
class Stock::Cn < BaseStock
  cattr_accessor :screenshot_key, instance_writer: false, instance_reader: false

  SZSE_ORDER_TYPES = {
    "0" => "限价委托",
    "Q" => "对手方最优价格",
    "S" => "本方最优价格",
    "T" => "即时成交剩余撤销",
    "U" => "五档即成剩余撤销",
    "V" => "全额成交或撤销"
  }

  SSE_ORDER_TYPES = {
    "0" => "限价委托",
    "U" => "五档即成剩余撤销",
    "R" => "五档即成剩余转限价"
  }

  def shanghai?
    exchange == "SSE"
  end

  def shenzhen?
    exchange == "SZSE"
  end

  def self.exchange
    @@exchange ||= Exchange::Cn.instance
  end

  def self.exchange=(exchange)
    @@exchange = exchange
  end

  def base_currency
    :cny
  end

  def currency
    :cny
  end

  def self.market_index_record
    BaseStock.csi300
  end

  def market_index_record
    BaseStock.csi300
  end

  def can_add_to_realtime_queue?
    false
  end

  def can_trade?
    exchange == "NEEQ" || is_index? ? false : true
  end

  def historical_quote_class
    HistoricalQuoteCn
  end

  def latest_close_market_time
    Exchange::Cn.instance.latest_close_market_time.to_s_full
  end

  def long_time_from_now
    2.years.from_now.to_s_full
  end

  def is_cn?
    true
  end

  def local_date
    trade_time.to_date rescue nil
  end

  def exchange_instance
    Exchange::Cn.instance
  end

  def historical_klass
    HistoricalQuoteCn
  end

  # 跌停
  def down_limit?
    realtime_price <= down_price
  end

  # 涨停
  def up_limit?
    realtime_price >= up_price
  end

  def open_down_limit?
    open <= down_price
  end

  def open_up_limit?
    open >= up_price
  end

  def order_types
    if shanghai?
      SSE_ORDER_TYPES
    elsif shenzhen?
      SZSE_ORDER_TYPES
    else
      {}
    end
  end

  # 涨停价
  def up_price
    (previous_close * up_ratio).round(2)
  end

  def up_ratio
    st? ? 1.05 : 1.1
  end

  # 跌停价
  def down_price
    (previous_close * down_ratio).round(2)
  end

  def down_ratio
    st? ? 0.95 : 0.9
  end

  # 是否为ST股票(规则为ST开头并且之后的字符为中文)
  def st?
    c_name =~ /(^*ST|^ST)[\u4E00-\u9FA5]/
  end

  # A股总市值实时计算(总股本 * 实时价格)
  def market_capitalization
    total_shares.to_i * realtime_price
  end

  # 流通市值(流通股本 * 实时价格)
  def non_restricted_market_capitalization
    non_restricted_shares.to_i * realtime_price
  end

  # 振幅( 当日最高价-当日最低价/昨日闭式价)
  def amplitude
    ((high - low) / previous_close * 100).round(3)
  end

  # 市净率(实时价格/每股净值产)
  def net_asset_rate
    return nil if net_asset_per_share.blank?

    (realtime_price / net_asset_per_share.to_f).round(2)
  end

  # 量比(公式: (当天成交量/过去的成交分钟数) / 过去五个工作日的每分钟平均成交量)
  # TODO 新股会有问题,新股可能上市没有五天
  def volume_ratio
    return 0 if five_days_volume.to_i.zero?

    volume_per_minutes = (volume.to_f / Exchange::Cn.instance.minutes_from_market_open)
    volume_per_minutes / (five_days_volume.to_f / 1200)
  end

  # 委比(公司: (买盘五档总和-卖盘五档总和)/(买盘五档总和+卖盘五档总和))
  # 结果百分比*100,比如45.49
  def bid_ratio
    bid, offer = bid_sizes.split(",").sum, offer_sizes.split(",").sum
    return 0 if (bid + offer).zero?

    ((bid - offer) * 100 / (bid + offer)).to_f.round(2)
  rescue
    0
  end

  # 当天成交额
  def turnover
    realtime_infos["total_value_trade"].to_f
  end

  # 最后交易时间
  def trade_time
    Time.parse($redis.hget(snapshot_key, "trade_time")) rescue nil
  end

  # 交易日期
  def trading_date
    trade_time.to_date rescue nil
  end

  # 根据股票显示开盘情况(APP用)
  def market_status
    exchange = Exchange::Base.by_area(:cn)
    return '' if exchange.blank?

    return "节假日休市" unless exchange.workday?

    now = Time.now.seconds_since_midnight.to_i
    if now < (9 * 3600 + 15 * 60)
      "未开盘"
    elsif now >= (9 * 3600 + 15 * 60) && now < (9 * 3600 + 30 * 60)
      "集合竞价"
    elsif now > (11 * 3600 + 30 * 60) && now < (13 * 3600)
      "午间休市"
    elsif now > (15 * 3600)
      "已收盘"
    else
      "交易中"
    end
  end

  def gem?
    listed_sector == LISTED_SECTORS[:gem_board]
  end

  def top_stocks_by_exchange(order = "desc", limit = 10)
    return super(order, limit) unless gem?

    $cache.fetch("cs:top_stocks:#{exchange}#{listed_sector}:#{order}", expires_in: 1.minutes) do
      self.class.where(exchange: exchange, listed_sector: listed_sector).select(:id, :name, :c_name)
        .includes(:stock_screener).joins(:stock_screener)
        .where("stock_screeners.change_rate is not null and stock_screeners.change_rate > -100")
        .order("stock_screeners.change_rate #{order}").limit(limit)
    end
  end
end
