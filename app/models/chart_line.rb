# 分时图
class ChartLine 
  attr_accessor :base_stock, :exchange, :area

  def initialize(base_stock)
    @base_stock = base_stock
    @exchange = Exchange::Base.by_area(base_stock.market_area)
    @area = base_stock.market_area
  end

  def intraday_date
    Exchange::Base.by_area(area).prev_latest_market_date
  end

  # one day
  def self.one_day_minutes(stock)
    ChartLine.new(stock).sync_one_day_cached
  end

  # todo: unused
  # return oneday and week
  def self.minute_prices(stock)
    chartline = ChartLine.new(stock)
    one_day = chartline.sync_one_day
    one_week = chartline.sync_5_day
    [one_day, one_week]
  end

  def self.cached_minute_prices(stock)
    exchange = Exchange::Base.by_area(stock.market_area)
    expires_in = exchange.seconds_from_now_to_open_time
    
    if exchange.delay_trading? || stock.foreign_index?
      self.minute_prices(stock)
    else
      $cache.fetch("minute_prices:#{stock.id}", :expires_in => expires_in){ self.minute_prices(stock) }
    end
  end

  def sync_one_day
    RestClient.api.stock.bar(base_stock.id, start_date: intraday_date, end_date: intraday_date, precision: 'minutes', period: 1)
  end

  def sync_one_day_cached
    if self.exchange.delay_trading?
      sync_one_day
    else
      expires_in = self.exchange.seconds_from_now_to_open_time
      $cache.fetch("one_day_minute_prices:#{self.base_stock.id}", :expires_in => expires_in){ sync_one_day }
    end
  end

  def sync_5_day
    RestClient.api.stock.bar(base_stock.id, start_date: intraday_date - 6, end_date: intraday_date, precision: 'minutes', period: 10)
  end
end
