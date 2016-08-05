class Stock::Us < BaseStock
  cattr_accessor :screenshot_key, instance_writer: false, instance_reader: false

  ORDER_TYPES = {"market" => "市价" , "limit" => "限价"}

  def self.exchange
    @@exchange||=Exchange::Us.instance
  end

  def self.exchange=(exchange)
    @@exchange = exchange
  end

  def self.market_index_record
    BaseStock.sp500
  end

  def market_index_record
    BaseStock.sp500
  end

  def can_add_to_realtime_queue?
    true
  end

  def can_trade?
    !is_index?
  end

  def latest_close_market_time
    Exchange::Us.instance.latest_close_market_time.to_s_full
  end

  def long_time_from_now
    2.years.from_now.to_s_full.to_estime.to_s_full
  end

  def is_cn?
    false
  end

  def local_date
    trade_time.to_date rescue nil
  end

  def exchange_instance
    Exchange::Us.instance
  end

  def historical_klass
    HistoricalQuote
  end

  # 跌停
  def down_limit?
    false
  end

  # 涨停
  def up_limit?
    false
  end

  def open_down_limit?
    false
  end

  def open_up_limit?
    false
  end

  def order_types
    ORDER_TYPES
  end
  
  # 交易日期
  def trading_date
    trade_time.to_date rescue nil
  end

  def trade_time
    Redis.current.hget(snapshot_key, "trade_time").in_time_zone('Eastern Time (US & Canada)')
  rescue
    nil
  end

  def market_capitalization
    super.to_s.try(:to_number) rescue 0
  end

end
